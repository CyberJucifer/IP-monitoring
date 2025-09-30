require 'rufus-scheduler'
require_relative '../config/logger'

class Scheduler
  class << self
    def start
      @scheduler = Rufus::Scheduler.new

      interval = (ENV['PING_INTERVAL'] || 60).to_i

      @scheduler.every "#{interval}s" do
        ping_all_enabled_ips
      end

      log_info("Scheduler started with #{interval}s interval")
    end

    def stop
      @scheduler&.shutdown
    end

    def ping_all_enabled_ips
      enabled_ips = IpAddress.where(enabled: true)

      enabled_ips.each do |ip_address|
        PingService.new(ip_address).ping
        log_debug("Pinged #{ip_address.ip} at #{Time.zone.now}")
      rescue StandardError => e
        log_error("Error pinging #{ip_address.ip}: #{e.message}")
      end
    end
  end
end
