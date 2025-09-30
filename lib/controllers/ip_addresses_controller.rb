require_relative 'base_controller'

class IpAddressesController < BaseController
  class << self
    def create(request_data)
      handle_request do
        validation_result = ParamsValidator.validate_ip_params(request_data)

        unless validation_result[:valid]
          return error_response(validation_result[:errors].join(', '))
        end

        ip_address = IpAddress.create(validation_result[:data])

        if ip_address.valid?
          success_response('IP address created', ip_address.values, status: 201)
        else
          error_response('Validation failed', data: { details: ip_address.errors })
        end
      end
    end

    def index
      handle_request do
        ip_addresses = IpAddress.all.map(&:values)
        json_response(ip_addresses)
      end
    end

    def show(id)
      handle_request do
        result = validate_and_find_ip(id)
        return result unless result[:success]

        json_response(result[:ip_address].values)
      end
    end

    def destroy(id)
      handle_request do
        result = validate_and_find_ip(id)
        return result unless result[:success]

        result[:ip_address].destroy
        success_response('IP address deleted', { ip: result[:ip_address].ip })
      end
    end

    def enable(id)
      handle_request do
        result = validate_and_find_ip(id)
        return result unless result[:success]

        result[:ip_address].enable!
        success_response('IP address enabled', { ip: result[:ip_address].ip })
      end
    end

    def disable(id)
      handle_request do
        result = validate_and_find_ip(id)
        return result unless result[:success]

        result[:ip_address].disable!
        success_response('IP address disabled', { ip: result[:ip_address].ip })
      end
    end

    def stats(id, time_from, time_to)
      handle_request do
        id_result = validate_and_find_ip(id)
        return id_result unless id_result[:success]

        time_result = validate_time_params(time_from, time_to)
        return time_result unless time_result[:success]

        stats = id_result[:ip_address].stats(time_result[:time_from], time_result[:time_to])
        json_response(stats)
      end
    end
  end
end
