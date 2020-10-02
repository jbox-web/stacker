module Stacker
  class CLI < Admiral::Command
    module Config
      def load_config
        config_file = File.read(flags.config)
        config = Stacker::Config.from_yaml(config_file)
        Stacker.config = config
      end

      def setup_log
        ::Log.setup do |c|
          backend = ::Log::IOBackend.new(File.open(Stacker.config.logfile, "a"))

          c.bind "*", :debug, backend
        end
      end
    end

    class Server < Admiral::Command
      include Config

      define_help description: "Run Stacker webserver"

      define_flag config : String,
        description: "Path to config file",
        long: config,
        short: c,
        default: "stacker.yml"

      def run
        load_config
        setup_log

        Kemal.run(args: nil) do |config|
          server = config.server.not_nil!
          server.bind_tcp Stacker.config.server_host, Stacker.config.server_port
          config.env = Stacker.config.server_environment
        end
      end
    end

    class Fetch < Admiral::Command
      include Config

      define_help description: "Fetch host pillars"

      define_argument host_name : String,
        description: "Fetch data for HOSTNAME",
        required: true

      define_flag config : String,
        description: "Path to config file",
        long: config,
        short: c,
        default: "stacker.yml"

      define_flag namespace : String,
        description: "Stack namespace to use",
        long: namespace,
        short: n,
        default: "default"

      define_flag grains : String,
        description: "Path to JSON grains file",
        long: grains,
        short: g,
        default: ""

      define_flag pillar : String,
        description: "Path to JSON pillar file",
        long: pillar,
        short: p,
        default: ""

      def run
        load_config
        setup_log

        result = Stacker::Runner.from_cli(arguments.host_name, flags.namespace, flags.grains, flags.pillar)
        puts result.to_json
      end
    end

    define_version Stacker::VERSION
    define_help description: "Stacker is Salt PillarStack in Crystal"

    register_sub_command server, Server, description: "Run Stacker webserver"
    register_sub_command fetch, Fetch, description: "Fetch host pillars"

    def run
      puts help
    end
  end
end
