module Stacker
  class CLI < Admiral::Command
    module Config
      def load_config
        begin
          config_file = File.read(flags.config)
        rescue e
          puts e.message; exit
        else
          config = Stacker::Config.from_yaml(config_file)
          Stacker.config = config
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

      define_flag grains : String,
        description: "Path to JSON grains file",
        long: grains,
        short: g,
        default: ""

      def run
        load_config

        grains =
          if flags.grains == ""
            {"id" => arguments.host_name}
          else
            JSON.parse(File.read(flags.grains))
          end

        processor = Stacker::Processor.new(Stacker.config.doc_root, Stacker.config.entrypoint, Stacker.config.stacks, Renderer.new(Stacker.config.doc_root))
        result = processor.run(arguments.host_name, grains)
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
