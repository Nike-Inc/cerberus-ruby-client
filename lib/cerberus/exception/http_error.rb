
module Cerberus
  module Exception

    ##
    # Custom exception raised when an HTTP exception is raised but we want to handle it differently
    # than simply presenting it to the end-user
    ##
    class HttpError < StandardError

      attr_reader :response

      ##
      #  Init with exception message and response object if one is available
      ##
      def initialize(httpMsg, responseObj = nil)

        @response = responseObj
        super("An error occurred executing the HTTP request: #{httpMsg}")

      end
    end
  end
end