#!/usr/bin/env ruby

require 'net/http'
require 'oj'
require 'uri'

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

puts('Testing IP Monitoring API...')
puts('=' * 50)

# Test health check
puts("\n1. Health check:")
response = make_request('GET', '/health')
puts("Status: #{response[:status]}\nResponse: #{response[:body]}")

# Test adding IP addresses
puts "\n2. Adding IP addresses:"
ips_to_add = [
  { ip: '8.8.8.8', enabled: true },
  { ip: '1.1.1.1', enabled: true },
  { ip: '2001:4860:4860::8888', enabled: false },
]

ip_ids = []
ips_to_add.each do |ip_data|
  response = make_request('POST', '/ips', ip_data)
  puts "Added #{ip_data[:ip]}: Status #{response[:status]}"
  ip_ids << response[:body]['id'] if response[:status] == 201
end

# Test listing IPs
puts "\n3. Listing all IPs:"
response = make_request('GET', '/ips')
puts "Status: #{response[:status]}\nIPs: #{response[:body].map do |ip|
  "#{ip['ip']} (enabled: #{ip['enabled']})"
end.join(', ')}"

# Test enabling/disabling
if ip_ids.any?
  puts "\n4. Testing enable/disable:"

  # Disable first IP
  response = make_request('POST', "/ips/#{ip_ids[0]}/disable")
  puts "Disabled IP #{ip_ids[0]}: Status #{response[:status]}"

  # Enable it back
  response = make_request('POST', "/ips/#{ip_ids[0]}/enable")
  puts "Enabled IP #{ip_ids[0]}: Status #{response[:status]}"
end

# Test statistics (will show error if no data)
if ip_ids.any?
  puts "\n5. Testing statistics:"
  time_from = 1.hour.ago.iso8601
  time_to = Time.now.iso8601

  response = make_request('GET', "/ips/#{ip_ids[0]}/stats?time_from=#{time_from}&time_to=#{time_to}")
  puts "Stats for IP #{ip_ids[0]}: Status #{response[:status]}\nResponse: #{response[:body]}"
end

puts "\n#{'=' * 50}"
puts 'API testing completed!'
