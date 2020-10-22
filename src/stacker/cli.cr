module Stacker
  class CLI < Admiral::Command
    module Config
      def load_config
        config_file = File.read(flags.config)
        config = Stacker::Config.from_yaml(config_file)
        Stacker.config = config
      end
    end

    class Server < Admiral::Command
      include Config

      define_help description: "Run Stacker webserver"

      define_flag config : String,
        description: "Path to config file",
        long: "config",
        short: "c",
        default: "stacker.yml"

      def run
        load_config
        Stacker.setup_log
        Stacker.setup_signals

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
        long: "config",
        short: "c",
        default: "stacker.yml"

      define_flag namespace : String,
        description: "Stack namespace to use",
        long: "namespace",
        short: "n",
        default: "default"

      define_flag grains : String,
        description: "Path to JSON grains file",
        long: "grains",
        short: "g",
        default: ""

      define_flag pillar : String,
        description: "Path to JSON pillar file",
        long: "pillar",
        short: "p",
        default: ""

      define_flag log_level : String,
        description: "Log level",
        long: "log-level",
        short: "l",
        default: "info"

      define_flag path : String,
        description: "Path to YAML file to debug",
        long: "path",
        short: "P",
        default: ""

      define_flag steps : Array(String),
        description: "Steps to debug",
        long: "step",
        short: "s",
        default: [] of String

      define_flag output_format : String,
        description: "Output format",
        long: "output-format",
        short: "o",
        default: "json"

      def run
        load_config
        Stacker.setup_log

        grains = flags.grains == "" ? {"id" => arguments.host_name} : Utils.load_json_file(flags.grains)
        pillar = flags.pillar == "" ? {} of String => String : Utils.load_json_file(flags.pillar)
        steps = flags.steps.empty? ? Stacker::Processor.valid_steps : Stacker::Processor.sanitize_steps_params(flags.steps)

        result = Stacker::Runner.process(arguments.host_name, flags.namespace, grains, pillar, flags.log_level, flags.path, steps)
        puts respond_with(flags.output_format, result)
      end

      private def respond_with(format, result)
        case format
        when "json"
          result.to_json
        when "yaml"
          result.to_yaml
        else
          result.to_json
        end
      end
    end

    class Info < Admiral::Command
      define_help description: "Show Stacker information"

      def run
        puts "version: #{Stacker::VERSION}"
        puts
        context = Context.new("")
        Utils.crinja_info(context.env)
      end
    end

    define_version Stacker::VERSION
    define_help description: "Stacker is Salt PillarStack in Crystal"

    register_sub_command info, Info, description: "Show Stacker information"
    register_sub_command server, Server, description: "Run Stacker webserver"
    register_sub_command fetch, Fetch, description: "Fetch host pillars"

    def run
      puts help
    end
  end
end
