module Stacker
  class Renderer
    Log = ::Log.for("renderer", ::Log::Severity::Info)

    def initialize(@root_dir : String, @entrypoint : String)
      @env = Crinja.new
      setup_env
    end

    def file_exist?(file)
      entrypoint = "#{@root_dir}/#{@entrypoint}/#{file}.yml"
      Utils.file_exists?(entrypoint)
    end

    def compile(file, data)
      input = File.read(file)

      begin
        template = @env.from_string(input)
        output = template.render(data)
      rescue e : Exception
        Log.error { "Error while compiling template #{file}" }
        Log.error { e.message }
        output = ""
      else
        Log.debug { "Compiled: #{file}" }
        Log.trace { "\n#{output}" }
      end

      output
    end

    private def setup_env
      @env.loader = Crinja::Loader::FileSystemLoader.new(@root_dir)
      @env.config.register_defaults = true
      @env.config.lstrip_blocks = true

      @env.filters["json"] = filter_json
      @env.filters["unique"] = filter_unique
      @env.filters["traverse"] = filter_traverse

      @env.functions["log"] = func_log
      @env.functions["dump"] = func_dump
      @env.functions["array_push"] = func_array_push
      @env.functions["merge_dict"] = func_merge_dict
    end

    private def filter_json
      Crinja.filter({indent: nil}, :json) do
        raw = target.raw
        indent = arguments.fetch("indent", 2).to_i
        String.build do |io|
          Crinja::JsonBuilder.to_json(io, raw, indent)
        end
      end
    end

    private def filter_traverse
      Crinja.filter({attribute: nil, default: nil}, :traverse) do
        attribute = arguments["attribute"]
        default = arguments["default"]
        result =
          begin
            Crinja::Resolver.resolve_dig(attribute, target)
          rescue
          end

        (result.nil? || result.to_s == "") ? default : result
      end
    end

    private def filter_unique
      Crinja.filter(:unique) do
        raw = target.raw
        return Crinja::Value.new("") unless raw.is_a?(Array)

        value = raw.uniq
        Crinja::Value.new(value)
      end
    end

    private def func_log
      Crinja.function({object: nil}, :log) do
        object = arguments["object"]
        Log.info { object }
        Crinja::Value.new("")
      end
    end

    private def func_dump
      Crinja.function({object: nil}, :dump) do
        object = arguments["object"]
        Log.info { "\n#{YAML.dump(object)}" }
        Crinja::Value.new("")
      end
    end

    private def func_array_push
      Crinja.function({array: [] of Crinja::Value, item: nil}, :array_push) do
        array = arguments["array"]
        item = arguments["item"]
        array.push(item)
      end
    end

    private def func_merge_dict
      Crinja.function({hash: nil, other: nil}, :merge_dict) do
        hash = arguments["hash"]
        other = arguments["other"]
        Stacker::Utils.deep_merge_crinja!(hash, other)
        hash
      end
    end
  end
end
