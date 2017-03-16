
module CerberusClient

  require('logger')

  ##
  # Instantiated by the Log singleton
  # can be replaced by the user provided the Logger supports the four log level outputs
  ##
  class DefaultLogger

    ##
    # Init the default logger
    ##
    def initialize
      @logger = Logger.new STDOUT
      # log level should be configurable
      @logger.level = Logger::DEBUG
      @logger.formatter = proc do |severity, datetime, progname, msg|

        severityFormatted = case severity
          when "ERROR"
            "\e[31m#{severity}\e[0m"
          when "WARN"
            "\e[33m#{severity}\e[0m"
          when "DEBUG"
            "\e[37m#{severity}\e[0m"
          else
            "#{severity}"
        end

        "#{datetime.strftime('%Y-%m-%d %H:%M:%S.%L')} #{severityFormatted}: #{msg}\n"
      end
    end

    ##
    # Log a error message to the default logger
    ##
    def error(msg)
      @logger.error(msg)
    end

    ##
    # Log a warning message to the default logger
    ##
    def warn(msg)
      @logger.warn(msg)
    end

    ##
    # Log a info message to the default logger
    ##
    def info(msg)
      @logger.info(msg)
    end

    ##
    # Log a debug message to the default logger
    ##
    def debug(msg)
      @logger.debug(msg)
    end
  end
end