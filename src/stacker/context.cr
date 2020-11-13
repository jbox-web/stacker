module Stacker
  class Context
    # Retrieve the Crinja runtime instance
    getter env

    # Retrieve the Crinja runtime root dir
    getter root_dir

    # This class is a wrapper around Crinja.
    #
    # It creates and setup a new Crinja environment.
    #
    # Filters and functions defined under `src/runtime` will be
    # automaticaly loaded.
    def initialize(@root_dir : String)
      @env = Crinja.new
      setup_env(@env, @root_dir)
    end

    private def setup_env(env, root_dir)
      env.loader = Crinja::Loader::FileSystemLoader.new(root_dir)
      env.config.register_defaults = true
      env.config.lstrip_blocks = true
    end
  end
end
