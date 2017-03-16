
module Cerberus
  module Exception

    ##
    # Custom exception raised when a provider can't successfully provide what is needed
    # and this is likely an expected condition
    ##
    class NoValueError < RuntimeError

      ##
      #  Init with exception message
      ##
      def initialize
        super("No value specified")
      end
    end
  end
end