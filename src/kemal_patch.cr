module Kemal
  def self.display_startup_message(config, server)
    previous_def
    SystemdNotify.new.ready
  end
end
