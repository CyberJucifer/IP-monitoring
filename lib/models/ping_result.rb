require_relative '../interfaces/model_interface'

class PingResult
  include Sequel::Model(DB[:ping_results])
  include ModelInterface

  plugin :timestamps, update_on_create: true

  def self.create_table
    DB.create_table? :ping_results do
      primary_key :id
      foreign_key :ip_address_id, :ip_addresses, null: false
      Float :rtt, null: true # null means packet loss
      Boolean :success, null: false, default: false
      DateTime :created_at, null: false

      index :ip_address_id
      index :created_at
      index [:ip_address_id, :created_at]
    end
  end

  def self.find(id)
    self[id]
  end

  def self.successful
    where(success: true)
  end

  def self.failed
    where(success: false)
  end

  def self.for_period(time_from, time_to)
    where(created_at: time_from..time_to)
  end

  def self.for_ip(ip_address_id)
    where(ip_address_id: ip_address_id)
  end

  def self.for_enabled_ips
    join(:ip_addresses, id: :ip_address_id).where(ip_addresses__enabled: true)
  end
end
