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

def test_validation
  puts '🧪 Testing Strong Parameters Validation'
  puts '=' * 50

  # Test cases for validation
  test_cases = [
    {
      name: 'Valid IPv4',
      data: { ip: '8.8.8.8', enabled: true },
      expected_status: 201,
    },
    {
      name: 'Valid IPv6',
      data: { ip: '2001:4860:4860::8888', enabled: false },
      expected_status: 201,
    },
    {
      name: 'Invalid IP format',
      data: { ip: 'invalid-ip', enabled: true },
      expected_status: 400,
    },
    {
      name: 'Missing IP field',
      data: { enabled: true },
      expected_status: 400,
    },
    {
      name: 'Missing enabled field',
      data: { ip: '8.8.8.8' },
      expected_status: 400,
    },
    {
      name: 'Non-boolean enabled',
      data: { ip: '8.8.8.8', enabled: 'yes' },
      expected_status: 400,
    },
    {
      name: 'Empty IP string',
      data: { ip: '', enabled: true },
      expected_status: 400,
    },
    {
      name: 'IP with whitespace',
      data: { ip: '  8.8.8.8  ', enabled: true },
      expected_status: 201,
    },
  ]

  test_cases.each_with_index do |test_case, index|
    puts "\n#{index + 1}. Testing: #{test_case[:name]}"
    puts "   Data: #{test_case[:data]}"

    response = make_request('POST', '/ips', test_case[:data])

    if response[:status] == test_case[:expected_status]
      puts "   ✅ PASS - Status: #{response[:status]}"
      if response[:status] == 400
        puts "   Error: #{response[:body]['error']}"
      end
    else
      puts "   ❌ FAIL - Expected: #{test_case[:expected_status]}, Got: #{response[:status]}"
      puts "   Response: #{response[:body]}"
    end
  end

  # Test ID validation
  puts "\n#{'=' * 50}"
  puts 'Testing ID Parameter Validation'
  puts '=' * 50

  id_test_cases = [
    { path: '/ips/abc/enable', name: 'Invalid ID format (enable)' },
    { path: '/ips/abc/disable', name: 'Invalid ID format (disable)' },
    { path: '/ips/abc/stats?time_from=2024-01-01T00:00:00Z&time_to=2024-01-02T00:00:00Z',
      name: 'Invalid ID format (stats)' },
    { path: '/ips/abc', name: 'Invalid ID format (delete)' },
    { path: '/ips/999/enable', name: 'Non-existent ID (enable)' },
    { path: '/ips/999/stats?time_from=2024-01-01T00:00:00Z&time_to=2024-01-02T00:00:00Z',
      name: 'Non-existent ID (stats)' },
  ]

  id_test_cases.each_with_index do |test_case, index|
    puts "\n#{index + 1}. Testing: #{test_case[:name]}"
    puts "   Path: #{test_case[:path]}"

    response = make_request('GET', test_case[:path])

    if [400, 404].include?(response[:status])
      puts "   ✅ PASS - Status: #{response[:status]}"
      puts "   Error: #{response[:body]['error']}"
    else
      puts "   ❌ FAIL - Expected 400 or 404, Got: #{response[:status]}"
      puts "   Response: #{response[:body]}"
    end
  end

  # Test time validation
  puts "\n#{'=' * 50}"
  puts 'Testing Time Parameter Validation'
  puts '=' * 50

  # First create a valid IP for testing
  puts "\nCreating test IP address..."
  response = make_request('POST', '/ips', { ip: '8.8.8.8', enabled: true })

  if response[:status] == 201
    ip_id = response[:body]['id']
    puts "✅ Created test IP with ID: #{ip_id}"

    time_test_cases = [
      {
        params: { time_from: 'invalid-time', time_to: '2024-01-02T00:00:00Z' },
        name: 'Invalid time format',
      },
      {
        params: {},
        name: 'Missing time parameters',
      },
      {
        params: { time_from: '2024-01-02T00:00:00Z', time_to: '2024-01-01T00:00:00Z' },
        name: 'time_from after time_to',
      },
      {
        params: { time_from: '2020-01-01T00:00:00Z', time_to: '2024-01-01T00:00:00Z' },
        name: 'Time range too large (4 years)',
      },
      {
        params: { time_from: '2024-01-01T00:00:00Z', time_to: '2025-01-01T00:00:00Z' },
        name: 'time_to in the future',
      },
    ]

    time_test_cases.each_with_index do |test_case, index|
      puts "\n#{index + 1}. Testing: #{test_case[:name]}"
      puts "   Params: #{test_case[:params]}"

      query_string = test_case[:params].map { |k, v| "#{k}=#{v}" }.join('&')
      path = "/ips/#{ip_id}/stats?#{query_string}"

      response = make_request('GET', path)

      if response[:status] == 400
        puts "   ✅ PASS - Status: #{response[:status]}"
        puts "   Error: #{response[:body]['error']}"
      else
        puts "   ❌ FAIL - Expected 400, Got: #{response[:status]}"
        puts "   Response: #{response[:body]}"
      end
    end

    # Clean up
    puts "\nCleaning up test IP..."
    make_request('DELETE', "/ips/#{ip_id}")
    puts '✅ Cleaned up'
  else
    puts "❌ Failed to create test IP: #{response[:body]}"
  end

  puts "\n#{'=' * 50}"
  puts '🎉 Validation testing completed!'
  puts '=' * 50
end

# Check if server is running
begin
  response = make_request('GET', '/health')
  if response[:status] != 200
    puts '❌ Server is not running. Please start it with:'
    puts '   make run'
    puts '   or'
    puts '   docker-compose up -d'
    exit 1
  end
rescue StandardError
  puts '❌ Cannot connect to server. Please start it with:'
  puts '   make run'
  puts '   or'
  puts '   docker-compose up -d'
  exit 1
end

test_validation
