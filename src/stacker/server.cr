module Stacker
  # :nodoc:
  class Server
    Log = ::Log.for("server", ::Log::Severity::Info)

    # Key under which a route stashes the body to render for an error status.
    ERROR_BODY = "stacker.error_body"

    # Kemal renders its own HTML page for a status that has no error handler, and
    # the Salt module parses the body as JSON. Every status Stacker answers with
    # therefore gets a handler returning the documented JSON body.
    {% for status_code in [400, 404, 500] %}
      error {{ status_code }} do |env|
        env.response.content_type = "application/json"
        env.get?(ERROR_BODY) || {"{{ status_code.id }}" => "Stacker: error"}.to_json
      end
    {% end %}

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
      host_name, namespace, level, format, path, steps = extract_params(env)
      grains, pillar = env.request.method == "GET" ? extract_grains_and_pillar(host_name) : extract_grains_and_pillar(host_name, env)

      result = Runner.process(host_name, namespace, grains, pillar, level, path, steps)
      respond_with(env, format, result)
    rescue e : Error
      respond_with_error(env, e)
    rescue e : Exception
      # An unexpected error must not reach Kemal: in development mode it would render
      # an exception page exposing source paths and code.
      Log.error(exception: e) { "Unexpected error while processing #{env.request.resource}" }
      respond_with_error(env, Error.new("internal error"))
    end

    private def self.extract_params(env)
      host_name = env.params.url["host"]
      namespace = env.params.query["n"]? || "default"
      level = env.params.query["l"]? || "info"
      format = env.params.query["f"]? || "json"
      path = env.params.query["p"]? || ""
      steps = env.params.query["s"]? ? Processor.sanitize_steps_params(env.params.query["s"].split(",")) : Processor.valid_steps
      {host_name, namespace, level, format, path, steps}
    end

    # GET request
    private def self.extract_grains_and_pillar(host_name : String)
      grains = {"id" => host_name}
      pillar = {} of String => String
      {grains, pillar}
    end

    # POST request
    private def self.extract_grains_and_pillar(host_name : String, env)
      body =
        begin
          env.params.json
        rescue e : Exception
          raise InvalidRequest.new(e.message)
        end

      grains = extract_object(body, "grains") || {"id" => host_name}
      pillar = extract_object(body, "pillar") || {} of String => String
      {grains, pillar}
    end

    # Read a JSON object from the request body, refusing any other JSON type.
    private def self.extract_object(body, key)
      value = body[key]?
      return nil if value.nil?
      raise InvalidRequest.new("#{key} must be an object") unless value.is_a?(Hash)

      value
    end

    private def self.respond_with(env, format, result)
      case format
      when "yaml"
        env.response.content_type = "application/x-yaml"
        result.to_yaml
      else
        env.response.content_type = "application/json"
        result.to_json
      end
    end

    # Hand the body over to the matching error handler: setting the status alone
    # would let Kemal render its own error page instead.
    private def self.respond_with_error(env, error : Error)
      body = error.response.to_json
      env.set(ERROR_BODY, body)
      env.response.status_code = error.status_code
      body
    end
  end
end
