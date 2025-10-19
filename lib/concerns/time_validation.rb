# Concern for time validation - DRY principle
module TimeValidation
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def validate_time_params(time_from, time_to)
      time_result = ParamsValidator.validate_time_params(time_from, time_to)
      return error_response(time_result[:errors].join(', ')) unless time_result[:valid]

      { success: true, time_from: time_result[:time_from], time_to: time_result[:time_to] }
    end
  end
end
