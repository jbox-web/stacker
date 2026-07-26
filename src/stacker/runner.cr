module Stacker
  module Runner
    Log = ::Log.for("runner", ::Log::Severity::Info)

    # A host name resolves a file under the entrypoint directory and is interpolated
    # in the stack config templates (`{{ minion_id }}.yml`). Anything that could walk
    # out of that directory, or expand as a glob, is rejected up front.
    VALID_HOST_NAME = /\A[a-zA-Z0-9][a-zA-Z0-9._-]*\z/

    def self.process(host_name, namespace, grains, pillar, level, path, steps)
      validate_host_name!(host_name)

      stack = Stacker.config.stacks[namespace]?

      if stack.nil?
        Log.info { "Namespace not found : #{namespace}" }
        raise NamespaceNotFound.new(namespace)
      end

      renderer = Renderer.new(context, Stacker.config.entrypoint, Logger.for("renderer", level))

      unless renderer.file_exist?(host_name)
        Log.info { "Host not found : #{host_name}" }
        raise HostNotFound.new(host_name)
      end

      processor = Processor.new(renderer, stack, Logger.for("processor", level))
      processor.run(host_name, grains, pillar, namespace, path, steps)
    end

    # Build the shared `Context` up front, so the first requests do not race to
    # initialize it.
    def self.warmup
      context
    end

    # :nodoc:
    #
    # The context (Crinja environment and its template cache) is shared by every
    # request, and rebuilt only when the configured doc_root changes.
    def self.context
      root_dir = Stacker.config.doc_root
      context = @@context

      return context if context && context.root_dir == root_dir

      @@context = Context.new(root_dir)
    end

    private def self.validate_host_name!(host_name)
      return if VALID_HOST_NAME.matches?(host_name)

      Log.info { "Invalid host name : #{host_name.inspect}" }
      raise InvalidHostName.new(host_name)
    end
  end
end
