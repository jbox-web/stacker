module Stacker
  class Processor
    Log = ::Log.for("processor", ::Log::Severity::Info)

    VALID_STEPS = ["compile", "yaml-load", "before-merge", "after-merge", "final"]

    # :nodoc:
    property grains : Hash(String, String) | Hash(String, JSON::Any) | JSON::Any

    # :nodoc:
    property pillar : Hash(String, String) | Hash(String, JSON::Any) | JSON::Any

    # :nodoc:
    def self.valid_steps
      VALID_STEPS
    end

    # :nodoc:
    def self.sanitize_steps_params(steps)
      steps.reject { |s| !valid_steps.includes?(s) }
    end

    def initialize(@renderer : Renderer, @stacks : Array(String))
      @stack = Pillar.new
      @host_name = ""
      @grains = {} of String => String
      @pillar = {} of String => String
      @namespace = ""
      @path = ""
      @current_path = ""
      @steps = [] of String
    end

    def run(host_name, grains, pillar, namespace, path, steps)
      @host_name = host_name
      @grains = grains
      @pillar = pillar
      @namespace = namespace
      @path = path
      @steps = steps

      with_debug_run do
        build_stack
      end

      @stack
    end

    private def build_stack
      @stacks.each do |stack|
        @current_path = stack.to_s

        result = @renderer.compile(stack, compilation_data)

        with_targeted_trace(step: "compile") do
          Log.trace { "\n#{result}" }
        end

        result = Utils.string_to_array(result)

        result.each do |file|
          load_pillars_from_stack(stack, file)
        end
      end

      with_targeted_trace(step: "final") do
        Log.trace { "Stack final:\n#{YAML.dump(@stack)}" }
      end
    end

    private def load_pillars_from_stack(stack, file)
      dirname = File.dirname(stack)
      files = Dir["#{dirname}/#{file}"].sort

      files.each do |file|
        @current_path = file.to_s

        Log.debug { "Loading: #{file}" }

        data = Pillar.new

        load_pillars_from_file(dirname, file, data)

        with_debug_stack do
          Pillar.deep_merge!(@stack, data)
        end
      end
    end

    private def load_pillars_from_file(dirname, file, data)
      Log.debug { "Compiling: #{file}" }

      yaml = @renderer.compile(file, compilation_data.merge({"stack_path" => dirname}))

      with_targeted_trace(step: "compile") do
        Log.trace { "\n#{yaml}" }
      end

      return if yaml.empty?

      hash =
        begin
          Pillar.yaml_to_pillar(yaml)
        rescue e : YAML::ParseException
          Log.error { "Error while parsing yaml #{file}" }
          Log.error { e.message }
          Log.error { yaml }
          nil
        end

      return if hash.nil?

      with_targeted_trace(step: "yaml-load") do
        Log.trace { "Loaded:\n#{YAML.dump(hash)}" }
      end

      Log.debug { "Merging: #{file}" }

      Pillar.deep_merge!(data, hash)
    end

    private def compilation_data
      {"minion_id" => @host_name, "grains" => @grains, "pillar" => @pillar, "stack" => @stack}
    end

    private def with_debug_run(&block)
      Log.info { "Building stack for: #{@host_name} (namespace: #{@namespace})" }
      yield
      Log.info { "End of stack build for: #{@host_name} (namespace: #{@namespace})" }
    end

    private def with_debug_stack(&block)
      with_targeted_trace(step: "before-merge") do
        Log.trace { "Stack before:\n#{YAML.dump(@stack)}" }
      end

      yield

      with_targeted_trace(step: "after-merge") do
        Log.trace { "Stack after:\n#{YAML.dump(@stack)}" }
      end
    end

    private def with_targeted_trace(step, &block)
      if targeted_path? && targeted_step?(step)
        yield
      end
    end

    private def targeted_path?
      @path == "" || @current_path == @path
    end

    private def targeted_step?(step)
      @steps == self.class.valid_steps || @steps.includes?(step)
    end
  end
end
