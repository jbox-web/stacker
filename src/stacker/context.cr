module Stacker
  class Context
    getter env
    getter root_dir

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
