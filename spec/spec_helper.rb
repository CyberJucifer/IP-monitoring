require 'rspec'
require 'rack/test'
require 'factory_bot'
require 'oj'
require_relative '../app'
require_relative '../config/initializers'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.before do
    # Clean database before each test
    DB[:ping_results].delete
    DB[:ip_addresses].delete
  end

  config.after do
    # Clean database after each test
    DB[:ping_results].delete
    DB[:ip_addresses].delete
  end
end

def app
  IpMonitoringApp
end
