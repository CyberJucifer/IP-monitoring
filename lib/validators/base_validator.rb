class BaseValidator
  class << self
    def validate_presence(data, field, result)
      return if data[field] && !data[field].to_s.empty?

      result[:valid] = false
      result[:errors] << "#{field} is required"
    end

    def validate_type(data, field, expected_type, result)
      return if data[field].is_a?(expected_type)

      result[:valid] = false
      result[:errors] << "#{field} must be a #{expected_type.name.downcase}"
    end

    def validate_format(data, field, pattern, message, result)
      return if data[field].to_s.match?(pattern)

      result[:valid] = false
      result[:errors] << message
    end

    def validate_range(data, field, min, max, result)
      value = data[field]
      return unless value.is_a?(Numeric)

      if value < min || value > max
        result[:valid] = false
        result[:errors] << "#{field} must be between #{min} and #{max}"
      end
    end

    def validate_unpermitted_params(data, allowed_params, result)
      unpermitted = data.keys - allowed_params
      return if unpermitted.empty?

      result[:valid] = false
      result[:errors] << "Unpermitted parameters: #{unpermitted.join(', ')}"
    end

    def sanitize_string(value)
      return nil if value.nil?

      value.to_s.strip
    end

    def sanitize_boolean?(value)
      return false if value.nil? || value == false || value == 'false' || value.zero?

      true
    end
  end
end
