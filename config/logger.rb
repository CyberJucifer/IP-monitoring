require 'logger'
require 'fileutils'

# Create logs directory if it doesn't exist
FileUtils.mkdir_p('log')

# Configure logger
class AppLogger
  class << self
    def logger
      @logger ||= create_logger
    end

    private

    def create_logger
      logger = Logger.new(log_file, 'daily')
      logger.level = log_level
      logger.formatter = proc do |severity, datetime, _progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity.upcase}: #{msg}\n"
      end
      logger
    end

    def log_file
      case ENV.fetch('RACK_ENV', nil)
      when 'production'
        'log/production.log'
      when 'test'
        'log/test.log'
      else
        'log/development.log'
      end
    end

    def log_level
      case ENV.fetch('RACK_ENV', nil)
      when 'production'
        Logger::INFO
      when 'test'
        Logger::WARN
      else
        Logger::DEBUG
      end
    end
  end
end

# Global logger instance
$logger = AppLogger.logger

# Convenience methods
def log_info(message)
  $logger.info(message)
end

def log_debug(message)
  $logger.debug(message)
end

def log_warn(message)
  $logger.warn(message)
end

def log_error(message)
  $logger.error(message)
end

def log_fatal(message)
  $logger.fatal(message)
end


