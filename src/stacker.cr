# Load std libs
require "log"
require "yaml"

# Load external libs
require "crystal-env/core"

require "admiral"
require "crinja"
require "kemal"
require "systemd_notify"

# Set environment
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
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}
  GIT_REF = {{ `git log -n 1 --format="%H" | head -c 8`.chomp.stringify }}

  @@log_file : File? | IO::FileDescriptor?

  def self.version
    "#{VERSION} (#{GIT_REF})"
  end

  def self.config=(config : Config?)
    @@config = config
  end

  # Return the loaded configuration, or nil when none has been loaded yet.
  def self.config?
    @@config
  end

  def self.config
    @@config || raise Error.new("configuration not loaded")
  end

  def self.load_config(config_path)
    config_file = File.read(config_path)
    self.config = Config.from_yaml(config_file)
  end

  def self.setup_log
    ::Log.setup do |builder|
      builder.bind "*", :debug, logger
    end
  end

  def self.logger
    @@logger ||= ::Log::IOBackend.new(log_file)
  end

  def self.logger=(backend : ::Log::Backend?)
    @@logger = backend
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

  # Reopen the log file after a rotation.
  #
  # The backend memoizes the `File` it writes to, so it has to be dropped as well:
  # keeping it would go on writing to the rotated (renamed) file forever.
  def self.reopen_log_file!
    file = @@log_file
    @@log_file = nil
    @@logger = nil
    setup_log
    file.close if file && !file.closed? && !log_to_stdout?
  end

  def self.start_server
    # Kemal gets no arguments: the listening address always comes from the config
    # file, so letting it parse `-b`/`-p` would accept flags it then ignores.
    Kemal.run(args: nil) do |kemal_config|
      # Set environment
      kemal_config.env = config.server_environment

      # Start server
      server = kemal_config.server.not_nil! # ameba:disable Lint/NotNil
      server.bind_tcp config.server_host, config.server_port
    end
  end

  def self.stop_server
    Kemal.stop
  end

  # Return the arguments Stacker does not act on.
  #
  # Anything left once the subcommand and Stacker's own flags are removed would be
  # silently ignored, so the caller reports it instead of pretending to honour it.
  def self.unknown_args(args = ARGV.dup)
    args = args.dup

    # Skip the subcommand
    args.shift

    # Remove our own flags
    delete_flag_from_args(args, ["-c", "--config"])
  end

  private def self.delete_flag_from_args(args, flags)
    flags.each do |flag|
      while index = args.index(flag)
        # The flag may be the last argument: its value is then simply absent.
        args.delete_at(index + 1) if index + 1 < args.size
        args.delete_at(index)
      end
    end
    args
  end
end

# Start the CLI
unless Crystal.env.test?
  begin
    Stacker::CLI.run
  rescue e : Exception
    # stdout carries the machine readable result of `fetch`: diagnostics belong on
    # stderr, with the exception class and backtrace kept.
    STDERR.puts e.inspect_with_backtrace
    exit 1
  end
end
