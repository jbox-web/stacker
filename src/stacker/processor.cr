module Stacker
  class Processor
    property grains : Hash(String, String) | Hash(String, JSON::Any) | JSON::Any

    def initialize(@renderer : Renderer, @stacks : Array(String))
      @host_name = ""
      @grains = {} of String => String
      @pillar = Pillar.new
    end

    def run(host_name, grains, pillar)
      @host_name = host_name
      @grains = grains
      @pillar = pillar

      return {404 => "Not found"} unless valid?

      with_debug_run do
        build_stack
      end

      @pillar
    end

    private def valid?
      @renderer.file_exist?(@host_name)
    end

    private def build_stack
      @stacks.each do |stack|
        result = @renderer.compile(stack, compilation_data)
        result = Utils.string_to_array(result)

        result.each do |file|
          data = load_pillars_from_stack(stack, file)

          with_debug_pillar do
            Utils.deep_merge!(@pillar, data)
          end
        end
      end

      Log.trace { "Pillar final:\n#{YAML.dump(@pillar)}" }
    end

    private def load_pillars_from_stack(stack, file)
      dirname = File.dirname(stack)
      files = Dir["#{dirname}/#{file}"].sort

      Log.debug { "Loading: #{files} from #{dirname}" }

      data = Pillar.new

      files.each do |file|
        load_pillars_from_file(dirname, file, data)
      end

      Log.trace { "Data final:\n#{YAML.dump(data)}" }

      data
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
      {"grains" => @grains, "pillar" => @pillar}
    end

    private def with_debug_run(&block)
      Log.debug { "Building stack for: #{@host_name}" }
      yield
      Log.debug { "End of stack build for: #{@host_name}" }
    end

    private def with_debug_pillar(&block)
      Log.trace { "Pillar before:\n#{YAML.dump(@pillar)}" }
      yield
      Log.trace { "Pillar after:\n#{YAML.dump(@pillar)}" }
    end

    private def with_debug_data(data, &block)
      Log.trace { "Data before:\n#{YAML.dump(data)}" }
      yield
      Log.trace { "Data after:\n#{YAML.dump(data)}" }
    end
  end
end
