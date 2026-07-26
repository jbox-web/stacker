module Stacker
  class Context
    # Retrieve the `Crinja` runtime instance
    getter env

    # Retrieve the `Crinja` runtime root dir
    getter root_dir

    # `Context` is a wrapper around `Crinja`.
    #
    # It creates and setup a new `Crinja` environment to compile Jinja templates.
    #
    # Filters and functions defined under `src/runtime` will be
    # automaticaly loaded.
    def initialize(@root_dir : String)
      @env = Crinja.new
      @templates = {} of String => {mtime: Time, template: Crinja::Template}
      setup_env(@env, @root_dir)
    end

    # Return the parsed template for **file**, parsing it only when it is unknown or
    # has changed on disk.
    #
    # Parsing accounts for a significant share of a stack build (measured at ~38% of
    # the render time), and pillar templates change far less often than they are
    # rendered.
    def template(file : String) : Crinja::Template
      mtime = File.info(file).modification_time
      cached = @templates[file]?

      return cached[:template] if cached && cached[:mtime] == mtime

      template = @env.from_string(File.read(file))
      @templates[file] = {mtime: mtime, template: template}
      template
    end

    def self.crinja_info
      new("").crinja_info
    end

    def crinja_info
      [@env.filters, @env.tests, @env.functions, @env.tags, @env.operators].each do |library|
        puts "#{library.name}s:"
        names = library.keys
        names.sort.each do |name|
          feature = library[name]
          puts "  #{feature}"
        end
        puts
      end
    end

    private def setup_env(env, root_dir)
      env.loader = Crinja::Loader::FileSystemLoader.new(root_dir)
      env.config.register_defaults = true
      env.config.lstrip_blocks = true
    end
  end
end
