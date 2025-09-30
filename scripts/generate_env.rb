#!/usr/bin/env ruby

require 'securerandom'

def generate_password(length = 32)
  SecureRandom.alphanumeric(length)
end

def generate_secret_key
  SecureRandom.hex(64)
end

def generate_env_file
  puts '🔐 Generating secure environment configuration...'
  puts '=' * 50

  # Generate secure values
  db_password = generate_password(24)
  secret_key = generate_secret_key
  jwt_secret = generate_secret_key

  # Development .env content
  env_content = <<~ENV
    # Environment Configuration
    # Generated on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}

    # Database Configuration
    DB_HOST=localhost
    DB_PORT=5432
    DB_NAME=ip_monitoring
    DB_USER=postgres
    DB_PASSWORD=#{db_password}

    # Alternative: Full Database URL (overrides individual DB_* variables)
    # DATABASE_URL=postgres://username:password@host:port/database

    # Application Configuration
    RACK_ENV=development
    PORT=4567

    # Monitoring Configuration
    PING_INTERVAL=60
    PING_TIMEOUT=1

    # Security (for production)
    SECRET_KEY_BASE=#{secret_key}
    JWT_SECRET=#{jwt_secret}
  ENV

  # Production .env content
  production_env = <<~ENV
    # Environment Configuration - Production
    # Generated on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}

    # Database Configuration
    DB_HOST=localhost
    DB_PORT=5432
    DB_NAME=ip_monitoring
    DB_USER=postgres
    DB_PASSWORD=#{db_password}

    # Alternative: Full Database URL (overrides individual DB_* variables)
    # DATABASE_URL=postgres://username:password@host:port/database

    # Application Configuration
    RACK_ENV=production
    PORT=4567

    # Monitoring Configuration
    PING_INTERVAL=60
    PING_TIMEOUT=1

    # Security (for production)
    SECRET_KEY_BASE=#{secret_key}
    JWT_SECRET=#{jwt_secret}
  ENV

  # Example .env content (safe to commit)
  example_env = <<~ENV
    # Environment Configuration Example
    # Copy this file to .env and update the values for your local development

    # Database Configuration
    DB_HOST=localhost
    DB_PORT=5432
    DB_NAME=ip_monitoring
    DB_USER=postgres
    DB_PASSWORD=your_secure_password_here

    # Alternative: Full Database URL (overrides individual DB_* variables)
    # DATABASE_URL=postgres://username:password@host:port/database

    # Application Configuration
    RACK_ENV=development
    PORT=4567

    # Monitoring Configuration
    PING_INTERVAL=60
    PING_TIMEOUT=1

    # Security (for production)
    # SECRET_KEY_BASE=your_secret_key_base_here
    # JWT_SECRET=your_jwt_secret_here
  ENV

  # Write files
  File.write('.env', env_content)
  puts '✅ Generated .env file with secure credentials'

  File.write('.env.production', production_env)
  puts '✅ Generated .env.production file'

  File.write('.env.example', example_env)
  puts '✅ Generated .env.example file (safe to commit)'

  puts "\n🔒 Security Notes:"
  puts "- Database password: #{db_password[0..7]}... (24 characters)"
  puts "- Secret key: #{secret_key[0..15]}... (128 characters)"
  puts "- JWT secret: #{jwt_secret[0..15]}... (128 characters)"
  puts "\n⚠️  IMPORTANT:"
  puts '- Never commit .env files to version control'
  puts '- Use different passwords for production'
  puts '- Store production secrets in secure vaults'
  puts "\n📁 Files created:"
  puts '- .env (for development - DO NOT COMMIT)'
  puts '- .env.production (for production - DO NOT COMMIT)'
  puts '- .env.example (safe to commit - template for developers)'
end

def show_usage
  puts '🔐 Environment Configuration Generator'
  puts '=' * 40
  puts 'Usage: ruby scripts/generate_env.rb'
  puts ''
  puts 'This script will generate:'
  puts '- .env file with secure development credentials'
  puts '- .env.production file with secure production credentials'
  puts ''
  puts 'The generated files include:'
  puts '- Random database password (24 characters)'
  puts '- Random secret key base (128 characters)'
  puts '- Random JWT secret (128 characters)'
  puts ''
  puts '⚠️  Remember to:'
  puts '- Add .env* to .gitignore'
  puts '- Use different credentials for production'
  puts '- Store production secrets securely'
end

if ARGV.include?('--help') || ARGV.include?('-h')
  show_usage
else
  generate_env_file
end
