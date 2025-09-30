require_relative '../interfaces/validator_interface'
require_relative 'base_validator'

module ParamsValidator
  include ValidatorInterface

  class << self
    def validate_ip_params(data)
      result = { valid: true, errors: [], data: {} }

      BaseValidator.validate_type(data, nil, Hash, result)
      return result unless result[:valid]

      permitted_keys = %w[ip enabled]
      BaseValidator.validate_unpermitted_params(data, permitted_keys, result)
      return result unless result[:valid]

      BaseValidator.validate_presence(data, 'ip', result)
      return result unless result[:valid]

      ip_string = BaseValidator.sanitize_string(data['ip'])
      unless valid_ip?(ip_string)
        result[:valid] = false
        result[:errors] << 'ip is not a valid IP address'
        return result
      end
      result[:data][:ip] = ip_string

      result[:data][:enabled] = if data.key?('enabled')
                                  BaseValidator.sanitize_boolean?(data['enabled'])
                                else
                                  true
                                end

      result
    end

    def validate_id_param(id)
      result = { valid: true, errors: [], id: nil }

      if id.nil? || id.to_s.empty?
        result[:valid] = false
        result[:errors] << 'ID parameter is required'
        return result
      end

      begin
        parsed_id = Integer(id)
        if parsed_id <= 0
          result[:valid] = false
          result[:errors] << 'ID must be a positive integer'
          return result
        end
        result[:id] = parsed_id
      rescue ArgumentError
        result[:valid] = false
        result[:errors] << 'ID must be a valid integer'
        return result
      end

      result
    end

    def validate_time_params(time_from, time_to)
      result = { valid: true, errors: [], time_from: nil, time_to: nil }

      if time_from.nil? || time_from.to_s.empty?
        result[:valid] = false
        result[:errors] << 'time_from parameter is required'
        return result
      end

      if time_to.nil? || time_to.to_s.empty?
        result[:valid] = false
        result[:errors] << 'time_to parameter is required'
        return result
      end

      begin
        parsed_time_from = Time.parse(time_from)
        result[:time_from] = parsed_time_from
      rescue ArgumentError
        result[:valid] = false
        result[:errors] << 'time_from must be a valid ISO 8601 datetime'
        return result
      end

      begin
        parsed_time_to = Time.parse(time_to)
        result[:time_to] = parsed_time_to
      rescue ArgumentError
        result[:valid] = false
        result[:errors] << 'time_to must be a valid ISO 8601 datetime'
        return result
      end

      if parsed_time_from >= parsed_time_to
        result[:valid] = false
        result[:errors] << 'time_from must be before time_to'
        return result
      end

      if parsed_time_to - parsed_time_from > 365 * 24 * 60 * 60
        result[:valid] = false
        result[:errors] << 'Time range cannot exceed 1 year'
        return result
      end

      result
    end

    private

    def valid_ip?(ip_string)
      addr = IPAddr.new(ip_string)
      addr.ipv4? || addr.ipv6?
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
