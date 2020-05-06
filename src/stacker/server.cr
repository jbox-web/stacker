module Stacker
  class Server
    get "/" do
      "Stacker root"
    end

    get "/:host" do |env|
      host_name, format = extract_params(env)
      grains = {"id" => host_name}
      result = process(host_name, grains)

      respond_with(env, format, result)
    end

    post "/:host" do |env|
      host_name, format = extract_params(env)
      grains = JSON.parse(env.params.json.to_json)
      result = process(host_name, grains)

      respond_with(env, format, result)
    end

    private def self.extract_params(env)
      host_name = env.params.url["host"]
      format = env.params.query["f"]? || "json"
      {host_name, format}
    end

    private def self.respond_with(env, format, result)
      case format
      when "json"
        env.response.content_type = "application/json"
        result.to_json
      when "yaml"
        env.response.content_type = "application/x-yaml"
        result.to_yaml
      else
        env.response.content_type = "application/json"
        result.to_json
      end
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
