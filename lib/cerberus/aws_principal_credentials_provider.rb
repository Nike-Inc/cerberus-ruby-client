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

  ##
  # The AWS IAM principal credentials provider
  #
  # Tries to authenticate with Cerberus using the IAM role of the EC2 instance
  ##
  class AwsPrincipalCredentialsProvider

    # AWS metadata instance URL
    AWS_EC2_METADATA_URL = "http://169.254.169.254/latest/meta-data"
    # relative URI to look up AZ in AWS metadata svc
    REGION_REL_URI = "/placement/availability-zone"
    # relative URI to look up IAM role in AWS metadata svc
    EC2_INSTNACE_PROFILE_REL_URI = "/iam/info"
    # reference into the metadata data json we get to look up IAM role
    EC2_INSTANCE_PROFILE_ARN_KEY = 'InstanceProfileArn'
    # relative URI to look up IAM role in AWS metadata svc
    IAM_ROLE_NAME_REL_URI = "/iam/security-credentials/"
    # magic number is the index into a split role ARN to grab the acccount ID
    ROLE_ARN_ARRAY_INDEX_OF_ACCOUNT_NUM = 4
    # magic number is the index into a split role ARN to grab the role name
    ROLE_ARN_ARRAY_INDEX_OF_ROLENAME = 1
    # relative URI to get encrypted auth data from Cerberus
    ROLE_AUTH_REL_URI = "/v2/auth/iam-principal"
    # reference into the decrypted auth data json we get from Cerberus
    CERBERUS_AUTH_DATA_CLIENT_TOKEN_KEY = "client_token"
    CERBERUS_AUTH_DATA_LEASE_DURATION_KEY = "lease_duration"
    CERBERUS_AUTH_DATA_POLICIES_KEY = "policies"

    $stdout.sync = true
    LOGGER = CerberusUtils::Log.instance

    ##
    # Init AWS principal provider - needs cerberus base url
    ##
    def initialize(cerberus_url_resolver, region = nil, instance_metadata_url = AWS_EC2_METADATA_URL)
      @cerberus_base_url = CerberusUtils::get_url_from_resolver(cerberus_url_resolver)
      @client_token = nil
      @instance_metadata_url = instance_metadata_url
      @cerberus_auth_info = get_cerberus_auth_info(instance_metadata_url, region)

      LOGGER.debug("AwsPrincipalCredentialsProvider initialized with cerberus base url #{@cerberus_base_url}")
    end

    ##
    # Get credentials using AWS IAM role
    ##
    def get_client_token

      if (@cerberus_auth_info.nil?)
        raise Cerberus::Exception::NoValueError
      end

      if (@client_token.nil?)
        @client_token = get_credentials_from_cerberus
      end

      # using two if statements for nil v. expired makes logging easier..
      # the above we expect on startup, expiration is worth its own logging
      if (@client_token.expired?)
        LOGGER.debug("Existing client token has expired - refreshing from Cerberus...")
        @client_token = get_credentials_from_cerberus
      end

      return @client_token.authToken

    end

    private

    ##
    # Uses provided data to determine how to construct the CerberusAuthInfo for use by this provider
    ##
    def get_cerberus_auth_info(instance_metadata_url, region)
      LOGGER.debug("Getting IAM role info...")

      # if we have no metedata about how to auth, we do nothing
      # this is used in unit testing primarily
      if (instance_metadata_url.nil?)
        LOGGER.warn("Instance metadata URL is nil for role provider!")
        return nil;     
      else
        # collect instance metadata we need to auth with Cerberus
        return get_role_from_ec2_metadata(region)
      end
    end

    ##
    # Use the instance metadata to extract the role information
    #
    # Gets the IAM role name and account ID in a weird way due to how the
    # EC2 Metadata service disjointly provides the data
    #
    # This function should only be called from an EC2 instance otherwise the http
    # call will fail.
    ##
    def get_role_from_ec2_metadata(region)
      begin
        # instance_profile_arn = get_instance_profile_arn
        # account_id = get_account_id_from_principal_arn(instance_profile_arn)
        sts_client = Aws::STS::Client.new
        account_id = sts_client.get_caller_identity().account
        role_name = get_iam_role_name
        aws_region = region.nil? ? get_region_from_az(get_availability_zone): region
        
        iam_role_arn = "arn:aws:iam::#{account_id}:role/#{role_name}"

        LOGGER.debug("IAM Principal ARN: #{iam_role_arn}")
        LOGGER.debug("AWS Region: #{aws_region}")

        return CerberusAuthInfo.new(iam_role_arn, aws_region, nil)
      rescue Cerberus::Exception::HttpError
        LOGGER.error("Failed to get instance IAM role infor from metadata service")
        return nil
      end
    end

    ##
    # Reach out to the Cerberus management service and get an auth token
    ##
    def get_credentials_from_cerberus
      LOGGER.debug("Authenticating with instance IAM role...")
      begin
        authData = authenticate_with_cerberus(@cerberus_auth_info.iam_principal_arn, @cerberus_auth_info.region)

        LOGGER.debug("Got auth data from Cerberus. Attempting to decrypt...")

        # decrypt the data we got from cerberus to get the cerberus token
        kms = Aws::KMS::Client.new(region: @cerberus_auth_info.region)

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
    # Get the role name from EC@ Metadata
    ##
    def get_iam_role_name
      response = call_ec2_metadata_service(IAM_ROLE_NAME_REL_URI)
      response.body
    end

    ##
    # Read the IAM role ARN from the instance metadata
    # Will throw an HTTP exception if there is no IAM role associated with the instance
    ##
    def get_instance_profile_arn
      response = call_ec2_metadata_service(EC2_INSTNACE_PROFILE_REL_URI)
      json_response_body = JSON.parse(response.body)
      json_response_body[EC2_INSTANCE_PROFILE_ARN_KEY]
    end

    ##
    # Get the AWS account ID from the role ARN
    # Expects formatting [some value]:[some value]:[some value]::[account id]
    ##
    def get_account_id_from_principal_arn(principal_arn)
      principal_arn.split(':')[ROLE_ARN_ARRAY_INDEX_OF_ACCOUNT_NUM]
    end

    ##
    # Get the region from AWS instance metadata
    ##
    def get_availability_zone
      call_ec2_metadata_service(REGION_REL_URI).body
    end

    ##
    # Get region from AZ
    ##
    def get_region_from_az(az)
      az[0, az.length-1]
    end

    ##
    # Call the instance metadata service with a relative URI and return the response if the call succeeds
    # else throw an IOError for non-2xx responses and RuntimeError for any exceptions down the stack
    ##
    def call_ec2_metadata_service(relative_uri)
      url = URI(@instance_metadata_url + relative_uri)
      CerberusUtils::Http.new.make_http_call(url, 'GET', false)
    end

    ##
    #
    ##
    def authenticate_with_cerberus(iam_principal_arn, region)
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
