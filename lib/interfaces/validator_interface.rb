# Interface for all validators - Dependency Inversion Principle
module ValidatorInterface
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def validate(data)
      raise NotImplementedError, "#{self} must implement validate"
    end
  end

  def valid?
    raise NotImplementedError, "#{self.class} must implement valid?"
  end

  def errors
    raise NotImplementedError, "#{self.class} must implement errors"
  end
end
