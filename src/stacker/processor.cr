module Stacker
  class Processor
    Log = ::Log.for("processor", ::Log::Severity::Info)

    property grains : Hash(String, String) | Hash(String, JSON::Any) | JSON::Any
    property pillar : Hash(String, String) | Hash(String, JSON::Any) | JSON::Any

    def initialize(@renderer : Renderer, @stacks : Array(String))
      @stack = Pillar.new
      @host_name = ""
      @grains = {} of String => String
      @pillar = {} of String => String
      @namespace = ""
    end

    def run(host_name, grains, pillar, namespace)
      @host_name = host_name
      @grains = grains
      @pillar = pillar
      @namespace = namespace

      return {404 => "Not found"} unless valid?

      with_debug_run do
        build_stack
      end

      @stack
    end

    private def valid?
      @renderer.file_exist?(@host_name)
    end

    private def build_stack
      @stacks.each do |stack|
        result = @renderer.compile(stack, compilation_data)
        result = Utils.string_to_array(result)

        result.each do |file|
          load_pillars_from_stack(stack, file)
        end
      end

      Log.trace { "Stack final:\n#{YAML.dump(@stack)}" }
    end

    private def load_pillars_from_stack(stack, file)
      dirname = File.dirname(stack)
      files = Dir["#{dirname}/#{file}"].sort

      files.each do |file|
        Log.debug { "Loading: #{file}" }

        data = Pillar.new

        load_pillars_from_file(dirname, file, data)

        with_debug_stack do
          Utils.deep_merge!(@stack, data)
        end
      end
    end

    private def load_pillars_from_file(dirname, file, data)
      Log.debug { "Compiling: #{file}" }

      yaml = @renderer.compile(file, compilation_data.merge({"stack_path" => dirname}))
      return if yaml.empty?

      hash =
        begin
          Utils.yaml_to_hash(yaml)
        rescue e : YAML::ParseException
          Log.error { "Error while parsing yaml #{file}" }
          Log.error { e.message }
          Log.error { yaml }
          nil
        end

      return if hash.nil?

      Log.trace { "Loaded:\n#{YAML.dump(hash)}" }

      Log.debug { "Merging: #{file}" }

      Utils.deep_merge!(data, hash)
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
      Log.trace { "Stack before:\n#{YAML.dump(@stack)}" }
      yield
      Log.trace { "Stack after:\n#{YAML.dump(@stack)}" }
    end
  end
end
