require_relative 'base_controller'

class HealthController < BaseController
  class << self
    def check
      handle_request do
        health_data = {
          status: 'ok',
          timestamp: Time.zone.now.iso8601,
          version: '1.0.0',
          uptime: Time.zone.now - $start_time,
        }
        json_response(health_data)
      end
    end
  end
end
