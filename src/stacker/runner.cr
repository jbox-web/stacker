module Stacker
  class Runner
    def self.from_cli(host_name, namespace, grains, pillar, level)
      stack = Stacker.config.stacks[namespace]?
      raise ArgumentError.new("Namespace not found : #{namespace}") if stack.nil?

      process(host_name, grains, pillar, stack, namespace, level)
    end

    def self.from_web(host_name, namespace, grains, pillar, level)
      stack = Stacker.config.stacks[namespace]?
      return {"404" => "Namespace not found : #{namespace}"} if stack.nil?

      process(host_name, grains, pillar, stack, namespace, level)
    end

    def self.process(host_name, grains, pillar, stack, namespace, level)
      Utils.with_log_level(level) do
        process(host_name, grains, pillar, stack, namespace)
      end
    end

    def self.process(host_name, grains, pillar, stack, namespace)
      renderer = Renderer.new(Stacker.config.doc_root, Stacker.config.entrypoint)
      processor = Stacker::Processor.new(renderer, stack)
      processor.run(host_name, grains, pillar, namespace)
    end
  end
end
