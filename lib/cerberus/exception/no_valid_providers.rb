module Cerberus
  module Exception

    ##
    # Custom exception raised when no credentials providers can be found
    ##
    class NoValidProviders < RuntimeError

      ##
      #  Init with exception message
      ##
      def initialize
        super("No valid credentials providers could be found")
      end
    end
  end
end