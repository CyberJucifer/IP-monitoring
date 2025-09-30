# Interface for all services - Interface Segregation Principle
module ServiceInterface
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def perform(*args)
      raise NotImplementedError, "#{self} must implement perform"
    end
  end

  def call
    raise NotImplementedError, "#{self.class} must implement call"
  end
end

