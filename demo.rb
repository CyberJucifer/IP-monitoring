#!/usr/bin/env ruby

require 'net/http'
require 'oj'
require 'uri'
require 'time'

BASE_URL = 'http://localhost:4567'.freeze

def make_request(method, path, data = nil)
  uri = URI("#{BASE_URL}#{path}")

  case method.upcase
  when 'GET'
    request = Net::HTTP::Get.new(uri)
  when 'POST'
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = data.to_json if data
  when 'DELETE'
    request = Net::HTTP::Delete.new(uri)
  end

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  {
    status: response.code.to_i,
    body: begin
      Oj.load(response.body)
    rescue StandardError
      response.body
    end,
  }
end

def wait_for_pings(_ip_id, duration = 120)
  puts("Waiting for ping data to accumulate (#{duration} seconds)...")
  puts('The system will ping every 60 seconds by default.')

  duration.times do |i|
    print '.'
    sleep 1
    print "\r" if ((i + 1) % 10).zero?
  end
  puts "\n"
end

puts("🚀 IP Monitoring System Demo\n#{'=' * 50}")

# Check if server is running
begin
  response = make_request('GET', '/health')
  if response[:status] != 200
    puts("❌ Server is not running. Please start it with:\n   make run\n   or\n   docker-compose up -d")
    exit 1
  end
rescue StandardError
  puts("❌ Cannot connect to server. Please start it with:\n   make run\n   or\n   docker-compose up -d")
  exit 1
end

puts('✅ Server is running!')

# Add some IP addresses
puts("\n📝 Adding IP addresses for monitoring...")

test_ips = [
  { ip: '8.8.8.8', enabled: true, name: 'Google DNS' },
  { ip: '1.1.1.1', enabled: true, name: 'Cloudflare DNS' },
  { ip: '2001:4860:4860::8888', enabled: true, name: 'Google DNS IPv6' },
]

ip_ids = []
test_ips.each do |ip_data|
  response = make_request('POST', '/ips', { ip: ip_data[:ip], enabled: ip_data[:enabled] })
  if response[:status] == 201
    ip_id = response[:body]['id']
    ip_ids << ip_id
    puts("✅ Added #{ip_data[:name]} (#{ip_data[:ip]}) - ID: #{ip_id}")
  else
    puts("❌ Failed to add #{ip_data[:name]}: #{response[:body]}")
  end
end

if ip_ids.empty?
  puts('❌ No IP addresses were added. Exiting.')
  exit 1
end

# Show current IPs
puts("\n📋 Current IP addresses:")
response = make_request('GET', '/ips')
if response[:status] == 200
  response[:body].each do |ip|
    status = ip['enabled'] ? '🟢 Enabled' : '🔴 Disabled'
    puts("   #{ip['ip']} - #{status}")
  end
end

# Wait for some ping data
wait_for_pings(ip_ids.first, 30)

# Show statistics
puts("\n📊 Statistics for the first IP:")
if ip_ids.any?
  time_from = 1.hour.ago.iso8601
  time_to = Time.now.iso8601

  response = make_request('GET', "/ips/#{ip_ids[0]}/stats?time_from=#{time_from}&time_to=#{time_to}")

  if response[:status] == 200
    stats = response[:body]
    puts("   Total pings: #{stats['total_pings']}\n   Successful pings: #{stats['successful_pings']}\n   Packet loss: #{stats['packet_loss_percentage']}%")

    if stats['rtt_stats']
      rtt = stats['rtt_stats']
      rtt_stats = []
      rtt_stats << "Min: #{rtt['min']} ms" if rtt['min']
      rtt_stats << "Max: #{rtt['max']} ms" if rtt['max']
      rtt_stats << "Mean: #{rtt['mean']} ms" if rtt['mean']
      rtt_stats << "Median: #{rtt['median']} ms" if rtt['median']
      rtt_stats << "Std Dev: #{rtt['std_dev']} ms" if rtt['std_dev']
      puts("   RTT Statistics:\n     #{rtt_stats.join("\n     ")}") if rtt_stats.any?
    end
  else
    puts("   No statistics available yet: #{response[:body]}")
  end
end

# Test enable/disable
puts("\n🔄 Testing enable/disable functionality...")
if ip_ids.length > 1
  # Disable second IP
  response = make_request('POST', "/ips/#{ip_ids[1]}/disable")
  if response[:status] == 200
    puts("✅ Disabled IP #{ip_ids[1]}")
  end

  # Enable it back
  response = make_request('POST', "/ips/#{ip_ids[1]}/enable")
  if response[:status] == 200
    puts("✅ Re-enabled IP #{ip_ids[1]}")
  end
end

puts("\n🎉 Demo completed!")
puts("\nYou can continue using the API or check the web interface at:\n   http://localhost:4567/health\n\nTo stop the server, press Ctrl+C or run:\n   docker-compose down")
