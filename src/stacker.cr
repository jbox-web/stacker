require "yaml"
require "log"
require "admiral"
require "crinja"
require "kemal"

require "./crinja_patch"
require "./stacker/*"

module Stacker
  VERSION = "0.1.0"
  Log     = ::Log.for(self, ::Log::Severity::Info)

  def self.config=(config : Config)
    @@config = config
  end

  def self.config
    @@config ||= Config.from_yaml("")
  end
end

# Configure logger
Log.builder.bind "*", :debug, Log::IOBackend.new

# Start the CLI
Stacker::CLI.run
