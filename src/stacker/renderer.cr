module Stacker
  class Renderer
    Log = ::Log.for("renderer", ::Log::Severity::Info)

    def initialize(@context : Context, @entrypoint : String)
    end

    def file_exist?(file)
      entrypoint = "#{@context.root_dir}/#{@entrypoint}/#{file}.yml"
      Utils.file_exists?(entrypoint)
    end

    def compile(file, data)
      input = File.read(file)

      begin
        template = @context.env.from_string(input)
        output = template.render(data)
      rescue e : Exception
        Log.error { "Error while compiling template #{file}" }
        Log.error { e.message }
        output = ""
      else
        Log.debug { "Compiled: #{file}" }
      end

      output
    end
  end
end
