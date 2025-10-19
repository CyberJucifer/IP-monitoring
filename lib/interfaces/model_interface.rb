# Interface for all models - Open/Closed Principle
module ModelInterface
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def create_table
      raise NotImplementedError, "#{self} must implement create_table"
    end

    def all
      raise NotImplementedError, "#{self} must implement all"
    end

    def find(id)
      raise NotImplementedError, "#{self} must implement find"
    end
  end

  def valid?
    raise NotImplementedError, "#{self.class} must implement valid?"
  end

  def save
    raise NotImplementedError, "#{self.class} must implement save"
  end

  def destroy
    raise NotImplementedError, "#{self.class} must implement destroy"
  end

  def values
    raise NotImplementedError, "#{self.class} must implement values"
  end
end
