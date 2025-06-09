# :nodoc:
module Kemal
  # :nodoc:
  def self.display_startup_message(config, server)
    addresses = server.addresses.map { |address| "#{config.scheme}://#{address}" }.join ", "
    Log.info { "[#{config.env}] Kemal is ready to lead at #{addresses} (PID: #{Process.pid})" }
    SystemdNotify.new.ready
  end
end
