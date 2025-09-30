require_relative '../interfaces/model_interface'

class IpAddress
  include Sequel::Model(DB[:ip_addresses])
  include ModelInterface

  plugin :timestamps, update_on_create: true

  def self.create_table
    DB.create_table? :ip_addresses do
      primary_key :id
      String :ip, null: false, unique: true
      Boolean :enabled, default: true, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :ip
      index :enabled
    end
  end

  def self.find(id)
    self[id]
  end

  def self.valid_ip?(ip_string)
    addr = IPAddr.new(ip_string)
    addr.ipv4? || addr.ipv6?
  rescue IPAddr::InvalidAddressError
    false
  end

  def validate
    super
    errors.add(:ip, 'is required') if ip.nil? || ip.empty?
    errors.add(:ip, 'is not a valid IP address') unless self.class.valid_ip?(ip)
  end

  def enable!
    update(enabled: true)
  end

  def disable!
    update(enabled: false)
  end

  def enabled?
    enabled == true
  end

  def stats(time_from, time_to)
    StatsService.new(self, time_from, time_to).calculate
  end
end
