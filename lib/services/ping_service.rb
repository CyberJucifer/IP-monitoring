require 'net/ping'
require 'timeout'
require_relative '../interfaces/service_interface'

class PingService
  include ServiceInterface

  PING_TIMEOUT = (ENV['PING_TIMEOUT'] || 1).to_i

  def initialize(ip_address)
    @ip_address = ip_address
  end

  def call
    ping
  end

  def ping
    begin
      pinger = Net::Ping::ICMP.new(@ip_address.ip, nil, PING_TIMEOUT)

      success = Timeout.timeout(PING_TIMEOUT) do
        pinger.ping
      end

      if success && pinger.duration
        rtt = pinger.duration * 1000
        create_ping_result(rtt, true)
      else
        create_ping_result(nil, false)
      end
    rescue StandardError
      create_ping_result(nil, false)
    ensure
      pinger&.close
    end
  end

  private

  def create_ping_result(rtt, success)
    PingResult.create(
      ip_address_id: @ip_address.id,
      rtt: rtt,
      success: success,
      created_at: Time.zone.now
    )
  end
end
