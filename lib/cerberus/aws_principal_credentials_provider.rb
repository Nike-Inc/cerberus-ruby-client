module Cerberus

  require_relative('../cerberus_client/log')
  require_relative('../cerberus_client/http')
  require_relative('../cerberus_client')
  require_relative('exception/no_value_error')
  require_relative('exception/http_error')
  require_relative('cerberus_client_token')
  require_relative('aws_role_info')
  require('aws-sdk')
  require('net/http')
  require('json')
  require('base64')

  ##
  # The AWS IAM role credentials provider
  ##
  class AwsPrincipalCredentialsProvider

    # AWS metadata instance URL
    INSTANCE_METADATA_SVC_BASE_URL = "http://169.254.169.254/latest/meta-data"
    # relative URI to look up AZ in AWS metadata svc
    REGION_REL_URI = "/placement/availability-zone"
    # relative URI to look up IAM role in AWS metadata svc
    IAM_ROLE_INFO_REL_URI = "/iam/info"
    # reference into the metadata data json we get to look up IAM role
    IAM_ROLE_ARN_KEY = 'InstanceProfileArn'
    # relative URI to look up IAM role in AWS metadata svc
    IAM_ROLE_NAME_REL_URI = "/iam/security-credentials/"
    # magic number is the index into a split role ARN to grab the acccount ID
    ROLE_ARN_ARRAY_INDEX_OF_ACCOUNTNUM = 4
    # magic number is the index into a split role ARN to grab the role name
    ROLE_ARN_ARRAY_INDEX_OF_ROLENAME = 1
    # relative URI to get encrypted auth data from Cerberus
    ROLE_AUTH_REL_URI = "/v2/auth/iam-principal"
    # reference into the decrypted auth data json we get from Cerberus
    CERBERUS_AUTH_DATA_CLIENT_TOKEN_KEY = "client_token"
    CERBERUS_AUTH_DATA_LEASE_DURATION_KEY = "lease_duration"
    CERBERUS_AUTH_DATA_POLICIES_KEY = "policies"

    LOGGER = CerberusClient::Log.instance

    ##
    # Init AWS principal provider - needs vault base url
    ##
    def initialize(vaultBaseUrl)
      @vaultBaseUrl = vaultBaseUrl
      @clientToken = nil
      @role = get_role_info

      LOGGER.debug("AwsPrincipalCredentialsProvider initialized with vault base url #{@vaultBaseUrl}")
    end

    ##
    # Get credentials using AWS IAM role
    ##
    def getClientToken

      if (@role.nil?)
        raise Cerberus::Exception::NoValueError
      end

      if (@clientToken.nil?)
        @clientToken = getCredentialsFromCerberus
      end

      # using two if statements here just to make the logging easier..
      # the above we expect on startup, expiration is an interesting event worth a debug log all its own
      if (@clientToken.expired?)
        LOGGER.debug("Existing ClientToken has expired - refreshing from Cerberus...")
        @clientToken = getCredentialsFromCerberus
      end

      return @clientToken.authToken

    end

    private

    ##
    # Uses provided data to determine how to construct the AwsRoleInfo use by this provider
    ##
    def get_role_info
      begin
        return get_role_from_instance_metadata
      rescue Cerberus::Exception::HttpError
        return nil
      end
    end

    ##
    # Use the instance metadata to extract the role information
    # This function should only be called from an EC2 instance otherwise the http
    # call will fail.
    ##
    def get_role_from_instance_metadata
      role_arn = getIAMRoleARN
      region = getRegionFromAZ(getAvailabilityZone)
      account_id = getAccountIdFromRoleARN(role_arn)
      role_name = getIAMRoleName

      LOGGER.debug("roleARN #{role_arn}")
      LOGGER.debug("region #{region}")
      LOGGER.debug("accountId #{account_id}")
      LOGGER.debug("roleName #{role_name}")

      return AwsRoleInfo.new(role_name, region, account_id, nil)
    end

    ##
    # Reach out to the Cerberus management service and get an auth token
    ##
    def getCredentialsFromCerberus
      begin
        authData = doAuthWithCerberus(@role.account_id, @role.name, @role.region)

        LOGGER.debug("Got auth data from Cerberus. Attempting to decrypt...")

        # decrypt the data we got from cerberus to get the vault token
        kms = Aws::KMS::Client.new(region: @role.region, credentials: @role.credentials[:credentials])

        decryptedAuthDataJson = JSON.parse(kms.decrypt(ciphertext_blob: Base64.decode64(authData)).plaintext)

        LOGGER.debug("Decrypt successful.  Passing back Cerberus auth token.")
        # pass back a credentials object that will allow us to reuse it until it expires
        CerberusClientToken.new(decryptedAuthDataJson[CERBERUS_AUTH_DATA_CLIENT_TOKEN_KEY],
                                decryptedAuthDataJson[CERBERUS_AUTH_DATA_LEASE_DURATION_KEY],
                                decryptedAuthDataJson[CERBERUS_AUTH_DATA_POLICIES_KEY])

      rescue Cerberus::Exception::HttpError
        # catch http errors here and assert no value
        # this may not actually be the case, there are legitimate reasons HTTP can fail when it "should" work
        # but this is handled by logging - a warning is set in the log in during the HTTP call
        raise Cerberus::Exception::NoValueError
      end
    end

    ##
    # Get the AWS account ID from the role ARN
    # Expects formatting [some value]:[some value]:[some value]::[account id]
    ##
    def getAccountIdFromRoleARN(roleARN)
      roleARN.split(':')[ROLE_ARN_ARRAY_INDEX_OF_ACCOUNTNUM]
    end

    ##
    # Get the role name from EC@ Metadata
    ##
    def getIAMRoleName
      response = doHttpToMDService(IAM_ROLE_NAME_REL_URI)
      response.body
    end

    ##
    # Read the IAM role ARN from the instance metadata
    # Will throw an HTTP exception if there is no IAM role associated with the instance
    ##
    def getIAMRoleARN
      response = doHttpToMDService(IAM_ROLE_INFO_REL_URI)
      jsonResponseBody = JSON.parse(response.body)
      jsonResponseBody[IAM_ROLE_ARN_KEY]
    end

    ##
    # Get the region from AWS instance metadata
    ##
    def getAvailabilityZone
      doHttpToMDService(REGION_REL_URI).body
    end

    ##
    # Get region from AZ
    ##
    def getRegionFromAZ(az)
      az[0, az.length-1]
    end

    ##
    # Call the instance metadata service with a relative URI and return the response if the call succeeds
    # else throw an IOError for non-2xx responses and RuntimeError for any exceptions down the stack
    ##
    def doHttpToMDService(relUri)
      url = URI(INSTANCE_METADATA_SVC_BASE_URL + relUri)
      CerberusClient::Http.new.doHttp(url, 'GET', false)
    end

    ##
    #
    ##
    def doAuthWithCerberus(accountId, roleName, region)
      postJsonData = JSON.generate({:iam_principal_arn => "arn:aws:iam::#{accountId}:role/#{roleName}", :region => region})
      authUrl = URI(@vaultBaseUrl + ROLE_AUTH_REL_URI)
      useSSL = ! ("#{@vaultBaseUrl}".include? "localhost")
      authResponse = CerberusClient::Http.new.doHttp(authUrl, 'POST', useSSL, postJsonData)
      # if we got this far, we should have a valid response with encrypted data
      # send back the encrypted data
      JSON.parse(authResponse.body)['auth_data']
    end

  end
end
