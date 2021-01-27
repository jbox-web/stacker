# Load external libs
require "yaml"
require "log"
require "admiral"
require "crinja"
require "kemal"
require "systemd_notify"
require "crystal-env/core"
Crystal::Env.default("development")

# Load patches
require "./crinja_patch"
require "./kemal_patch"

# Load stacker
require "./stacker/*"

# Load Crinja extensions
require "./runtime/filter/*"
require "./runtime/function/*"

module Stacker
  VERSION = "0.1.0"

  @@log_file : File? | IO::FileDescriptor?

  def self.version
    VERSION
  end

  def self.config=(config : Config)
    @@config = config
  end

  def self.config
    @@config ||= Config.from_yaml("")
  end

  def self.load_config(config_path)
    config_file = File.read(config_path)
    self.config = Stacker::Config.from_yaml(config_file)
  end

  def self.setup_log
    ::Log.setup do |c|
      c.bind "*", :debug, logger
    end
  end

  def self.logger
    @@logger ||= ::Log::IOBackend.new(log_file)
  end

  def self.log_file
    @@log_file ||= log_to_stdout? ? STDOUT : File.open(config.log_file, "a")
  end

  def self.log_to_stdout?
    config.log_file.downcase == "stdout"
  end

  def self.setup_signals
    Signal::USR1.trap do
      reopen_log_file!
    end

    Signal::TERM.trap do
      stop_server
      close_log_file!
    end
  end

  def self.close_log_file!
    log_file.close
  end

  def self.reopen_log_file!
    @@log_file = nil
    setup_log
  end

  def self.start_server
    Kemal.run(args: nil) do |kemal_config|
      # Set environment
      kemal_config.env = config.server_environment

      # Start server
      server = kemal_config.server.not_nil!
      server.bind_tcp config.server_host, config.server_port
    end
  end

  def self.stop_server
    Kemal.stop
  end
end

# Start the CLI
unless Crystal.env.test?
  begin
    Stacker::CLI.run
  rescue e : Exception
    puts e.message
    exit 1
  end
end
