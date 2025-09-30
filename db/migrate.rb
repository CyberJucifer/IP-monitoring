#!/usr/bin/env ruby

require_relative '../config/initializers'

puts("Creating database tables...")

# Create tables
IpAddress.create_table
PingResult.create_table

puts "Database tables created successfully!"

# Create some sample data for testing
if ENV['RACK_ENV'] == 'development'
  puts "Creating sample data..."
  
  # Add some common IPs for testing
  sample_ips = [
    { ip: '8.8.8.8', enabled: true },
    { ip: '1.1.1.1', enabled: true },
    { ip: '2001:4860:4860::8888', enabled: false } # Google DNS IPv6
  ]
  
  sample_ips.each do |ip_data|
    ip = IpAddress.find(ip: ip_data[:ip]) || IpAddress.create(ip_data)
    puts "Created/found IP: #{ip.ip} (enabled: #{ip.enabled})"
  end
  
  puts "Sample data created!"
end

puts "Migration completed!"
