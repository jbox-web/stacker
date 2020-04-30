module Stacker
  class Server
    get "/" do
      "Stacker root"
    end

    get "/:host" do |env|
      host_name = env.params.url["host"]
      grains = {"id" => host_name}
      result = process(host_name, grains)

      env.response.content_type = "application/json"
      result.to_json
    end

    post "/:host" do |env|
      host_name = env.params.url["host"]
      grains = JSON.parse(env.params.json.to_json)
      result = process(host_name, grains)

      env.response.content_type = "application/json"
      result.to_json
    end

    private def self.process(host_name, grains)
      processor = Stacker::Processor.new(Stacker.config.doc_root, Stacker.config.entrypoint, Stacker.config.stacks, renderer)
      processor.run(host_name, grains)
    end

    private def self.renderer
      @@renderer ||= Renderer.new(Stacker.config.doc_root)
    end
  end
end
