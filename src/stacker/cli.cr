module Stacker
  # :nodoc:
  class CLI < Admiral::Command
    class Server < Admiral::Command
      define_help description: "Run Stacker webserver"

      # ameba:disable Lint/UselessAssign
      define_flag config : String,
        description: "Path to config file",
        long: "config",
        short: "c",
        default: "stacker.yml"

      def run
        Stacker.load_config(flags.config)
        Stacker.setup_log
        Stacker.setup_signals
        Stacker.start_server
      end
    end

    class Fetch < Admiral::Command
      define_help description: "Fetch host pillars"

      # ameba:disable Lint/UselessAssign
      define_argument host_name : String,
        description: "Fetch data for HOSTNAME",
        required: true

      # ameba:disable Lint/UselessAssign
      define_flag config : String,
        description: "Path to config file",
        long: "config",
        short: "c",
        default: "stacker.yml"

      # ameba:disable Lint/UselessAssign
      define_flag namespace : String,
        description: "Stack namespace to use",
        long: "namespace",
        short: "n",
        default: "default"

      # ameba:disable Lint/UselessAssign
      define_flag grains : String,
        description: "Path to JSON grains file",
        long: "grains",
        short: "g",
        default: ""

      # ameba:disable Lint/UselessAssign
      define_flag pillar : String,
        description: "Path to JSON pillar file",
        long: "pillar",
        short: "p",
        default: ""

      # ameba:disable Lint/UselessAssign
      define_flag log_level : String,
        description: "Log level",
        long: "log-level",
        short: "l",
        default: "info"

      # ameba:disable Lint/UselessAssign
      define_flag path : String,
        description: "Path to YAML file to debug",
        long: "path",
        short: "P",
        default: ""

      # ameba:disable Lint/UselessAssign
      define_flag steps : Array(String),
        description: "Steps to debug",
        long: "step",
        short: "s",
        default: [] of String

      # ameba:disable Lint/UselessAssign
      define_flag output_format : String,
        description: "Output format",
        long: "output-format",
        short: "o",
        default: "json"

      def run
        Stacker.load_config(flags.config)
        Stacker.setup_log

        grains = flags.grains.empty? ? {"id" => arguments.host_name} : load_json_file(flags.grains)
        pillar = flags.pillar.empty? ? {} of String => String : load_json_file(flags.pillar)
        steps = flags.steps.empty? ? Processor.valid_steps : Processor.sanitize_steps_params(flags.steps)

        result = Runner.process(arguments.host_name, flags.namespace, grains, pillar, flags.log_level, flags.path, steps)
        puts respond_with(flags.output_format, result)
      end

      private def load_json_file(file)
        JSON.parse(File.read(file))
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
        puts "version: #{Stacker.version}"
        puts
        puts "crystal:"
        puts Crystal::DESCRIPTION
        puts
        Context.crinja_info
      end
    end

    define_version Stacker.version
    define_help description: "Stacker is Salt PillarStack in Crystal"

    register_sub_command info, Info, description: "Show Stacker information"
    register_sub_command server, Server, description: "Run Stacker webserver"
    register_sub_command fetch, Fetch, description: "Fetch host pillars"

    def run
      puts help
    end
  end
end
