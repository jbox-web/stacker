module Stacker
  class Runner
    def self.from_cli(host_name, namespace, grains, pillar)
      stack = Stacker.config.stacks[namespace]?
      raise ArgumentError.new("Namespace not found : #{namespace}") if stack.nil?

      grains = grains == "" ? {"id" => host_name} : Utils.load_json_file(grains)
      pillar = pillar == "" ? {} of String => String : Utils.load_json_file(pillar).as_h
      pillar = Utils.convert_hash(pillar)

      process(host_name, grains, pillar, stack)
    end

    def self.from_web(host_name, namespace, grains, pillar, level)
      stack = Stacker.config.stacks[namespace]?
      return {"404" => "Namespace not found : #{namespace}"} if stack.nil?

      Utils.with_log_level(level) do
        process(host_name, grains, pillar, stack)
      end
    end

    def self.process(host_name, grains, pillar, stack)
      renderer = Renderer.new(Stacker.config.doc_root)
      processor = Stacker::Processor.new(Stacker.config.doc_root, Stacker.config.entrypoint, stack, renderer)
      processor.run(host_name, grains, pillar)
    end
  end
end