module Stacker
  class Server
    get "/" do
      "Stacker root"
    end

    get "/:host" do |env|
      process(env)
    end

    post "/:host" do |env|
      process(env)
    end

    private def self.process(env)
      host_name, namespace, level, format = extract_params(env)
      grains, pillar = env.request.method == "GET" ? extract_grains_and_pillar(host_name) : extract_grains_and_pillar(host_name, env)

      result = Stacker::Runner.process(host_name, namespace, grains, pillar, level)
      respond_with(env, format, result)
    end

    private def self.extract_params(env)
      host_name = env.params.url["host"]
      namespace = env.params.query["n"]? || "default"
      level = env.params.query["l"]? || "info"
      format = env.params.query["f"]? || "json"
      {host_name, namespace, level, format}
    end

    # GET request
    private def self.extract_grains_and_pillar(host_name : String)
      grains = {"id" => host_name}
      pillar = {} of String => String
      {grains, pillar}
    end

    # POST request
    private def self.extract_grains_and_pillar(host_name : String, env)
      grains = env.params.json["grains"]? ? env.params.json["grains"].as(Hash) : {"id" => host_name}
      pillar = env.params.json["pillar"]? ? env.params.json["pillar"].as(Hash) : {} of String => String
      {grains, pillar}
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
  end
end
