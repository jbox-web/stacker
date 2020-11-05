module Kemal
  def self.display_startup_message(config, server)
    addresses = server.addresses.map { |address| "#{config.scheme}://#{address}" }.join ", "
    log "[#{config.env}] Kemal is ready to lead at #{addresses} (PID: #{Process.pid})"
    SystemdNotify.new.ready
  end
end
