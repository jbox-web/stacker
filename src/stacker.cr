require "yaml"
require "log"
require "admiral"
require "crinja"
require "kemal"

require "./crinja_patch"
require "./stacker/*"

module Stacker
  VERSION = "0.1.0"

  def self.config=(config : Config)
    @@config = config
  end

  def self.config
    @@config ||= Config.from_yaml("")
  end
end

# Start the CLI
begin
  Stacker::CLI.run
rescue e : Exception
  puts e.message
  exit 1
end
