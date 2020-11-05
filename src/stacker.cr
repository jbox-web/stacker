require "yaml"
require "log"
require "admiral"
require "crinja"
require "kemal"
require "systemd_notify"

require "./crinja_patch"
require "./kemal_patch"
require "./stacker/*"

module Stacker
  VERSION = "0.1.0"

  @@log_file : File? | IO::FileDescriptor?

  def self.config=(config : Config)
    @@config = config
  end

  def self.config
    @@config ||= Config.from_yaml("")
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
      Kemal.stop
      log_file.close
    end
  end

  def self.reopen_log_file!
    @@log_file = nil
    setup_log
  end
end

# Start the CLI
begin
  Stacker::CLI.run
rescue e : Exception
  puts e.message
  exit 1
end
