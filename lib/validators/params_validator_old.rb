require_relative '../interfaces/validator_interface'
require_relative 'base_validator'

module ParamsValidator
  include ValidatorInterface

  class << self
    def validate_ip_params(data)
      result = { valid: true, errors: [], data: {} }

      # Check if data is a hash
      unless data.is_a?(Hash)
        result[:valid] = false
        result[:errors] << 'Request body must be a JSON object'
        return result
      end

      # Check for unpermitted parameters
      permitted_keys = %w[ip enabled]
      unpermitted = data.keys - permitted_keys
      if unpermitted.any?
        result[:valid] = false
        result[:errors] << "Unpermitted parameters: #{unpermitted.join(', ')}"
      end

      # Validate required fields
      unless data.key?('ip')
        result[:valid] = false
        result[:errors] << 'Missing required field: ip'
      end

      unless data.key?('enabled')
        result[:valid] = false
        result[:errors] << 'Missing required field: enabled'
      end

      # Validate IP format if present
      if data['ip'] && !IpAddress.valid_ip?(data['ip'])
        result[:valid] = false
        result[:errors] << 'Invalid IP address format'
      end

      # Validate enabled field type
      if data.key?('enabled') && ![true, false].include?(data['enabled'])
        result[:valid] = false
        result[:errors] << 'Field "enabled" must be boolean (true/false)'
      end

      # Sanitize and prepare data if valid
      if result[:valid]
        result[:data] = {
          ip: data['ip']&.strip,
          enabled: data['enabled'],
        }
      end

      result
    end

    def validate_id_param(id)
      result = { valid: true, id: nil, error: nil }

      unless /^\d+$/.match?(id)
        result[:valid] = false
        result[:error] = 'Invalid IP address ID format'
        return result
      end

      parsed_id = id.to_i
      if parsed_id <= 0
        result[:valid] = false
        result[:error] = 'IP address ID must be a positive integer'
        return result
      end

      result[:id] = parsed_id
      result
    end

    def validate_time_params(time_from, time_to)
      result = { valid: true, errors: [], time_from: nil, time_to: nil }

      unless time_from && time_to
        result[:valid] = false
        result[:errors] << 'Missing required parameters: time_from, time_to'
        return result
      end

      begin
        parsed_from = Time.parse(time_from)
        parsed_to = Time.parse(time_to)

        # Validate time range
        if parsed_from >= parsed_to
          result[:valid] = false
          result[:errors] << 'time_from must be earlier than time_to'
        end

        # Validate time range is not too large (max 1 year)
        if parsed_to - parsed_from > 365 * 24 * 60 * 60
          result[:valid] = false
          result[:errors] << 'Time range cannot exceed 1 year'
        end

        # Validate time is not too far in the past (max 2 years)
        if parsed_from < Time.now - (2 * 365 * 24 * 60 * 60)
          result[:valid] = false
          result[:errors] << 'time_from cannot be more than 2 years in the past'
        end

        # Validate time is not in the future
        if parsed_to > Time.now
          result[:valid] = false
          result[:errors] << 'time_to cannot be in the future'
        end

        if result[:valid]
          result[:time_from] = parsed_from
          result[:time_to] = parsed_to
        end
      rescue ArgumentError
        result[:valid] = false
        result[:errors] << 'Invalid time format. Use ISO 8601 format (e.g., 2024-01-01T00:00:00Z)'
      end

      result
    end

    def sanitize_ip_data(data)
      return data unless data.is_a?(Hash)

      {
        ip: data['ip']&.strip,
        enabled: data['enabled'],
      }
    end

    # Additional validation methods for better security
    def validate_string_param(value, field_name, options = {})
      return { valid: false, error: "#{field_name} is required" } if value.nil? || value.empty?

      if options[:max_length] && value.length > options[:max_length]
        return { valid: false,
                 error: "#{field_name} exceeds maximum length of #{options[:max_length]}" }
      end

      if options[:pattern] && !value.match?(options[:pattern])
        return { valid: false, error: "#{field_name} format is invalid" }
      end

      { valid: true, value: value.strip }
    end

    def validate_boolean_param(value, field_name)
      return { valid: false, error: "#{field_name} is required" } if value.nil?

      case value
      when true, false
        { valid: true, value: value }
      when 'true', 'false'
        { valid: true, value: value == 'true' }
      else
        { valid: false, error: "#{field_name} must be boolean (true/false)" }
      end
    end

    def validate_integer_param(value, field_name, options = {})
      return { valid: false, error: "#{field_name} is required" } if value.nil? || value.empty?

      begin
        parsed = Integer(value)

        if options[:min] && parsed < options[:min]
          return { valid: false, error: "#{field_name} must be at least #{options[:min]}" }
        end

        if options[:max] && parsed > options[:max]
          return { valid: false, error: "#{field_name} must be at most #{options[:max]}" }
        end

        { valid: true, value: parsed }
      rescue ArgumentError
        { valid: false, error: "#{field_name} must be a valid integer" }
      end
    end
  end
end
