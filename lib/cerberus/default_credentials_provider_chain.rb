require_relative('../cerberus_client')
require_relative('../cerberus_utils/log')
require_relative('../cerberus_utils/utils')
require_relative('exception/no_value_error')
require_relative('exception/no_valid_providers')
require_relative('aws_principal_credentials_provider')
require_relative('env_credentials_provider')

module Cerberus

  ##
  # Default credentials provider chain
  ##
  class DefaultCredentialsProviderChain

    # AWS metadata instance URL
    AWS_EC2_METADATA_URL = "http://169.254.169.254/latest/meta-data"

    def initialize(url_resolver, region = nil, instance_metadata_url = AWS_EC2_METADATA_URL)

      # return default array of providers
      @providers = [Cerberus::EnvCredentialsProvider.new,
                    Cerberus::AwsPrincipalCredentialsProvider.new(url_resolver, region, instance_metadata_url)]
    end

    ##
    # Return the first provider in the default hierarchy that has a valid token
    ##
    def get_credentials_provider
      @providers.each { |p|
        begin
          # if token is assigned, that's the provider we want.
          # providers must throw NoValueError so that we can fall to the next provider if necessary
          CerberusUtils::get_credentials_from_provider(p)
          return p

        rescue Cerberus::Exception::NoValueError
          next
        end
      }

      # we should have found and returned a valid provider above, else there's a problem
      CerberusUtils::Log.instance.error("Could not find a valid provider")
      raise Cerberus::Exception::NoValidProviders.new
    end
  end
end
