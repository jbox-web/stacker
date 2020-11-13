module Stacker
  module Runner
    Log = ::Log.for("runner", ::Log::Severity::Info)

    def self.process(host_name, namespace, grains, pillar, level, path, steps)
      stack = Stacker.config.stacks[namespace]?

      if stack.nil?
        Log.info { "Namespace not found : #{namespace}" }
        return {"404" => "Stacker: namespace not found"}
      end

      Logger.with_log_level(level) do
        run(host_name, namespace, grains, pillar, stack, path, steps)
      end
    end

    # :nodoc:
    def self.run(host_name, namespace, grains, pillar, stack, path, steps)
      if renderer.file_exist?(host_name)
        processor = Processor.new(renderer, stack)
        processor.run(host_name, grains, pillar, namespace, path, steps)
      else
        Log.info { "Host not found : #{host_name}" }
        {404 => "Stacker: host not found"}
      end
    end

    # :nodoc:
    def self.renderer
      @@renderer ||= begin
        context = Context.new(Stacker.config.doc_root)
        Renderer.new(context, Stacker.config.entrypoint)
      end
    end
  end
end
