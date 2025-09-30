require 'sequel'
require 'dotenv'

Dotenv.load

# Database configuration from environment variables
database_url = ENV['DATABASE_URL'] || 
  "postgres://#{ENV['DB_USER'] || 'postgres'}:#{ENV['DB_PASSWORD'] || 'password'}@#{ENV['DB_HOST'] || 'localhost'}:#{ENV['DB_PORT'] || '5432'}/#{ENV['DB_NAME'] || 'ip_monitoring'}"

DB = Sequel.connect(database_url)

# Enable connection pooling
DB.pool.max_connections = 20

# Enable logging in development
DB.loggers << Logger.new($stdout) if ENV['RACK_ENV'] == 'development'
