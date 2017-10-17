module Cerberus

  require_relative('../cerberus_utils/log')
  require_relative('../cerberus_utils/http')
  require_relative('../cerberus_utils/utils')
  require_relative('../cerberus_client')
  require_relative('exception/no_value_error')
  require_relative('exception/http_error')
  require_relative('cerberus_client_token')
  require_relative('cerberus_auth_info')
  require('aws-sdk')
  require('net/http')
  require('json')
  require('base64')
  require('securerandom')

  ##
  # The AWS IAM role credentials provider
  # 
  # Tries to uthenticate with Cerberus using the EC2 Instance Profile ARN
  ##
  class AwsAssumeRoleCredentialsProvider

    # relative URI to get encrypted auth data from Cerberus
    ROLE_AUTH_REL_URI = "/v2/auth/iam-principal"
    # reference into the decrypted auth data json we get from Cerberus
    CERBERUS_AUTH_DATA_CLIENT_TOKEN_KEY = "client_token"
    CERBERUS_AUTH_DATA_LEASE_DURATION_KEY = "lease_duration"
    CERBERUS_AUTH_DATA_POLICIES_KEY = "policies"

    $stdout.sync = true 
    LOGGER = CerberusUtils::Log.instance

    ##
    # Init AWS role provider - needs cerberus base url.  Instance metadata service url is optional to make unit tests
    # easier and so we can provide a hook to set this via config as needed
    ##
    def initialize(cerberus_url_resolver, iam_role_arn, region)
      @cerberus_base_url = CerberusUtils::get_url_from_resolver(cerberus_url_resolver)
      @client_token = nil
      @cerberus_auth_info = get_assumed_role_info(iam_role_arn, region)

      LOGGER.debug("AwsAssumeRoleCredentialsProvider initialized with cerberus base url #{@cerberus_base_url}")
    end

    ##
    # Get credentials using AWS IAM role
    ##
    def get_client_token

      if (@cerberus_auth_info.nil?)
        LOGGER.warn("Instance metadata URL is nil for role provider!")
        raise Cerberus::Exception::NoValueError
      end

      if (@client_token.nil?)
        @client_token = get_credentials_from_cerberus
      end

      # using two if statements here just to make the logging easier..
      # the above we expect on startup, expiration is an interesting event worth a debug log all its own
      if (@client_token.expired?)
        LOGGER.debug("Existing ClientToken has expired - refreshing from Cerberus...")
        @client_token = get_credentials_from_cerberus
      end

      return @client_token.authToken

    end

    private

    ##
    # Get an CerberusAuthInfo object from the provided data
    ##
    def get_assumed_role_info(iam_role_arn, region)

      begin
        num_chars = 10  # magic number - shouldn't be too long to avoide session name length limits
        random_string = SecureRandom.hex(num_chars/2)  # hex method produces double the inputted num
        assume_role_session_name = "cerb-assume-role-session-#{random_string}"

        LOGGER.debug("role: #{iam_role_arn}")
        LOGGER.debug("region: #{region}")
        LOGGER.debug("session name: #{assume_role_session_name}")

        role_creds = Aws::AssumeRoleCredentials.new(
            client: Aws::STS::Client.new(region: region),
            role_arn: iam_role_arn,
            role_session_name: assume_role_session_name)

        return CerberusAuthInfo.new(iam_role_arn, region, credentials: role_creds)
      rescue
        LOGGER.error("Failed to assume role: #{iam_role_arn}, region: #{region}")
        return nil
      end
    end

    ##
    # Reach out to the Cerberus management service and get an auth token
    ##
    def get_credentials_from_cerberus
      LOGGER.debug("Authenticating with assumed role...")
      begin
        authData = do_auth_with_cerberus(@cerberus_auth_info.iam_principal_arn, @cerberus_auth_info.region)

        LOGGER.debug("Got auth data from Cerberus. Attempting to decrypt...")

        # decrypt the data we got from cerberus to get the cerberus token
        kms = Aws::KMS::Client.new(region: @cerberus_auth_info.region, credentials: @cerberus_auth_info.credentials[:credentials])

        decryptedAuthDataJson = JSON.parse(kms.decrypt(ciphertext_blob: Base64.decode64(authData)).plaintext)

        LOGGER.debug("Decrypt successful. Passing back Cerberus auth token.")
        # pass back a credentials object that will allow us to reuse it until it expires
        CerberusClientToken.new(decryptedAuthDataJson[CERBERUS_AUTH_DATA_CLIENT_TOKEN_KEY],
                                decryptedAuthDataJson[CERBERUS_AUTH_DATA_LEASE_DURATION_KEY],
                                decryptedAuthDataJson[CERBERUS_AUTH_DATA_POLICIES_KEY])

      rescue Cerberus::Exception::HttpError
        # catch http errors here and assert no value
        # this may not actually be the case, there are legitimate reasons HTTP can fail when it "should" work
        # but this is handled by logging - a warning is set in the log in during the HTTP call
        LOGGER.error("Failed to authenticate with assumed role: #{@cerberus_auth_info.iam_principal_arn},
           region: #{@cerberus_auth_info.region}.")
        raise Cerberus::Exception::NoValueError
      end
    end

    ##
    #
    ##
    def do_auth_with_cerberus(iam_principal_arn, region)
      post_json_data = JSON.generate({:iam_principal_arn => iam_principal_arn, :region => region})
      auth_url = URI(@cerberus_base_url + ROLE_AUTH_REL_URI)
      use_ssl = ! @cerberus_base_url.include?("localhost")
      auth_response = CerberusUtils::Http.new.make_http_call(auth_url, 'POST', use_ssl, post_json_data)
      # if we got this far, we should have a valid response with encrypted data
      # send back the encrypted data
      JSON.parse(auth_response.body)['auth_data']
    end

  end
end
