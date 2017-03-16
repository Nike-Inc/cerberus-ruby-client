

module Cerberus

  require_relative('../cerberus_client/log')

  ##
  # Object to hold the Cerberus client token credentials and check for expiration and refresh
  ##
  class CerberusClientToken

    attr_reader :authToken
    attr_reader :cacheLifetimeSec

    ##
    # Init with an authToken.  Expired will be true approximately cacheLifetimeSec seconds from when new is called.
    # Optionally, set the cache lifetime.  For now this is primarily used for testing.
    ##
    def initialize(authToken, cacheLifetimeSec, policiesArray)
      @createTime = Time.now
      @cacheLifetimeSec = cacheLifetimeSec
      @policies = policiesArray
      CerberusClient::Log.instance.debug("AwsCredentials cache lifetime set to #{@cacheLifetimeSec} seconds")
      CerberusClient::Log.instance.debug("AwsCredentials policies: #{@policies.join(", ")}")
      @authToken = authToken
    end

    ##
    # Return true if cache lifetime has expired
    # This object doesn't enforce expiration - someone else can worry about making sure the credentials are valid
    ##
    def expired?
      ((@createTime + @cacheLifetimeSec) <=> Time.now) == -1
    end

  end
end