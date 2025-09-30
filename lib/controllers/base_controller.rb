require_relative '../concerns/time_validation'

class BaseController
  include TimeValidation

  class << self
    def handle_request
      yield
    rescue Oj::ParseError
      { status: 400, body: Oj.dump({ error: 'Invalid JSON format' }) }
    rescue StandardError => e
      log_error("Controller error: #{e.message}")
      { status: 422, body: Oj.dump({ error: 'Something went wrong' }) }
    end

    def json_response(data, status: 200)
      { status: status, body: Oj.dump(data) }
    end

    def error_response(message, status: 400)
      { status: status, body: Oj.dump({ error: message }) }
    end

    def success_response(message, data = nil, status: 200)
      response = { message: message }
      response.merge!(data) if data
      { status: status, body: Oj.dump(response) }
    end

    def validate_and_find_ip(id)
      id_result = ParamsValidator.validate_id_param(id)
      return error_response(id_result[:errors].join(', ')) unless id_result[:valid]

      ip_address = IpAddress.find(id_result[:id])
      return error_response('IP address not found', status: 404) unless ip_address

      { success: true, ip_address: ip_address }
    end
  end
end
