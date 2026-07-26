module Stacker
  class Renderer
    # Log instance used by the `log` and `dump` template functions, which are explicit
    # user calls and are therefore never filtered by the per-request verbosity.
    Log = ::Log.for("renderer", ::Log::Severity::Info)

    def initialize(@context : Context, @entrypoint : String, @log : ::Log = Log)
    end

    # Check that **file** designates a pillar entrypoint inside the configured
    # entrypoint directory.
    #
    # The resolved path is compared to the entrypoint directory so a host name
    # carrying `..` cannot reach a file outside of it.
    def file_exist?(file)
      entrypoint_dir = File.expand_path("#{@context.root_dir}/#{@entrypoint}")
      entrypoint = File.expand_path("#{entrypoint_dir}/#{file}.yml")

      return false unless entrypoint.starts_with?("#{entrypoint_dir}#{File::SEPARATOR}")

      File.exists?(entrypoint)
    end

    def compile(file, data)
      output =
        begin
          @context.template(file).render(data)
        rescue e : Exception
          @log.error { "Error while compiling template #{file}" }
          @log.error { e.message }
          raise RenderError.new("#{file}: #{e.message}", cause: e)
        end

      @log.debug { "Compiled: #{file}" }

      output
    end
  end
end
