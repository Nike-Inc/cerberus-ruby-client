
module Cerberus
  module Exception

    ##
    # Custom exception raised when Vault sends us a bad request with a "permissions error"
    #
    # Since Vault wants to pass back 400 bad request for both paths we don't have access to
    # and paths that don't actually exist at all, I'm sending back a specific error so that implementing clients
    # can at least understand the situation they find themselves in
    ##
    class AmbiguousVaultBadRequest < RuntimeError

      ##
      #  Init with exception message
      ##
      def initialize()
        super("Vault sent back 400, Bad Request 'permissions error'. This means that 1) the root path may not exist 2) the account used may not have access to the path or 3) you actually can't be authenticated.")
      end
    end
  end
end