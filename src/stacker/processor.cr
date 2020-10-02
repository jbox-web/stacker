module Stacker
  class Processor
    property grains : Hash(String, String) | Hash(String, JSON::Any) | JSON::Any

    def initialize(@renderer : Renderer, @stacks : Array(String))
      @host_name = ""
      @grains = {} of String => String
      @pillar = Pillar.new
      @stack = Pillar.new
    end

    def run(host_name, grains, pillar)
      @host_name = host_name
      @grains = grains
      @pillar = pillar

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
        Log.debug { "Loading: #{file} from #{dirname}" }

        data = Pillar.new

        load_pillars_from_file(dirname, file, data)

        Log.trace { "Loaded:\n#{YAML.dump(data)}" }

        with_debug_stack do
          Utils.deep_merge!(@stack, data)
        end
      end
    end

    private def load_pillars_from_file(dirname, file, data)
      Log.debug { "Compiling: #{file}" }

      yaml = @renderer.compile(file, compilation_data.merge({"stack_path" => dirname}))
      return if yaml.empty?

      hash = Utils.yaml_to_hash(yaml, file)
      return if hash.nil?

      Log.debug { "Merging: #{file}" }

      with_debug_data(data) do
        Utils.deep_merge!(data, hash)
      end
    end

    private def compilation_data
      {"grains" => @grains, "pillar" => @pillar, "stack" => @stack}
    end

    private def with_debug_run(&block)
      Log.debug { "Building stack for: #{@host_name}" }
      yield
      Log.debug { "End of stack build for: #{@host_name}" }
    end

    private def with_debug_stack(&block)
      Log.trace { "Stack before:\n#{YAML.dump(@stack)}" }
      yield
      Log.trace { "Stack after:\n#{YAML.dump(@stack)}" }
    end

    private def with_debug_data(data, &block)
      Log.trace { "Data before:\n#{YAML.dump(data)}" }
      yield
      Log.trace { "Data after:\n#{YAML.dump(data)}" }
    end
  end
end
