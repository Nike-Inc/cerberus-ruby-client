


##
# Fake logger to test logging implementation
##
class FakeLogger

  ##
  # Init the default logger
  ##
  def initialize
    @logger = Logger.new STDOUT
    # log level should be configurable
    @logger.level = Logger::DEBUG
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "Fake logger doesn't care about your message, chomp, chomp\n"
    end
  end

  ##
  # Log a error message to the fake logger
  ##
  def error(msg)
    @logger.error(msg)
  end

  ##
  # Log a warning message to the fake logger
  ##
  def warn(msg)
    @logger.warn(msg)
  end

  ##
  # Log a info message to the fake logger
  ##
  def info(msg)
    @logger.info(msg)
  end

  ##
  # Log a debug message to the fake logger
  ##
  def debug(msg)
    @logger.debug(msg)
  end
end