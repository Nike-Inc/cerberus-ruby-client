


##
# Fake logger to test logging implementation
##
class FakeBadLogger

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

  # fake bad logger doesn't implement any of the methods he should... bad logger
end