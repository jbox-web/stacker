module Stacker
  class Runner
    Log = ::Log.for("runner", ::Log::Severity::Info)

    def self.process(host_name, namespace, grains, pillar, level)
      stack = Stacker.config.stacks[namespace]?

      if stack.nil?
        Log.info { "Namespace not found : #{namespace}" }
        return {"404" => "Stacker: namespace not found"}
      end

      Utils.with_log_level(level) do
        run(host_name, namespace, grains, pillar, stack)
      end
    end

    def self.run(host_name, namespace, grains, pillar, stack)
      renderer = Renderer.new(Stacker.config.doc_root, Stacker.config.entrypoint)

      if renderer.file_exist?(host_name)
        processor = Stacker::Processor.new(renderer, stack)
        processor.run(host_name, grains, pillar, namespace)
      else
        Log.info { "Host not found : #{host_name}" }
        {404 => "Stacker: host not found"}
      end
    end
  end
end
