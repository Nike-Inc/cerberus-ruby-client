module CerberusClient

  require_relative('default_logger')
  require('singleton')

  ##
  # Singleton providing logging capabilities for the Cerberus Client
  # Users can setup their own logger by calling Log.instance.setLoggingProvider
  # and impelmenting the four log level output methods
  ##
  class Log
    include Singleton

    attr_reader :logProvider

    ##
    # Called by Singleton to setup our instance - default logger instantiated
    # can be replaced by the user
    ##
    def initialize
      @logProvider = DefaultLogger.new
    end

    ##
    # Set the logger to be used by Cerberus Client
    ##
    def setLoggingProvider(logProvider)
      @logProvider = logProvider
    end

    ##
    # Log a error message to the default logger
    ##
    def error(msg)
      @logProvider.error(msg)
    end

    ##
    # Log a warning message to the default logger
    ##
    def warn(msg)
      @logProvider.warn(msg)
    end

    ##
    # Log a info message to the default logger
    ##
    def info(msg)
      @logProvider.info(msg)
    end

    ##
    # Log a debug message to the default logger
    ##
    def debug(msg)
      @logProvider.debug(msg)
    end
  end
end