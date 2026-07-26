module Stacker
  # Base class of every error Stacker reports to its callers.
  #
  # Each error carries the HTTP status and the response body historically returned
  # by the web server, so the CLI and the web server report failures identically.
  # The Salt module matches on those bodies: they must not change.
  class Error < Exception
    def status_code : Int32
      500
    end

    def response : Hash(String, String)
      {status_code.to_s => "Stacker: #{response_message}"}
    end

    def response_message : String
      message.to_s
    end
  end

  # The requested host name is not a name Stacker accepts.
  class InvalidHostName < Error
    def status_code : Int32
      400
    end

    def response_message : String
      "invalid host name"
    end
  end

  # The request body could not be parsed as the expected JSON document.
  class InvalidRequest < Error
    def status_code : Int32
      400
    end

    def response_message : String
      "invalid request body"
    end
  end

  # No `<host_name>.yml` file exists under the configured entrypoint.
  class HostNotFound < Error
    def status_code : Int32
      404
    end

    def response_message : String
      "host not found"
    end
  end

  # The requested namespace is not declared in the `stacks` configuration.
  class NamespaceNotFound < Error
    def status_code : Int32
      404
    end

    def response_message : String
      "namespace not found"
    end
  end

  # A template could not be rendered.
  #
  # This is always fatal for the whole build: rendering it as an empty string would
  # deliver a truncated stack that is indistinguishable from a complete one.
  #
  # The response stays generic on purpose. The offending file name, the template
  # source and the underlying error are written to the log, not handed to a client
  # that may not be entitled to them.
  class RenderError < Error
    def response_message : String
      "template error"
    end
  end

  # A rendered pillar file could not be loaded as a YAML mapping.
  class PillarError < Error
    def response_message : String
      "pillar error"
    end
  end
end
