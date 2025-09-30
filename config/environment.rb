# Environment configuration with secure defaults
ENV['RACK_ENV'] ||= 'development'
ENV['PORT'] ||= '4567'
ENV['PING_INTERVAL'] ||= '60'
ENV['PING_TIMEOUT'] ||= '1'

# Timezone configuration
require 'tzinfo'
ENV['TZ'] ||= 'UTC'
Time.zone = ENV['TZ']

# Database configuration from environment variables
ENV['DB_HOST'] ||= 'localhost'
ENV['DB_PORT'] ||= '5432'
ENV['DB_NAME'] ||= 'ip_monitoring'
ENV['DB_USER'] ||= 'postgres'
ENV['DB_PASSWORD'] ||= 'password'

# Construct DATABASE_URL if not provided
unless ENV['DATABASE_URL']
  ENV['DATABASE_URL'] = "postgres://#{ENV['DB_USER']}:#{ENV['DB_PASSWORD']}@#{ENV['DB_HOST']}:#{ENV['DB_PORT']}/#{ENV['DB_NAME']}"
end
