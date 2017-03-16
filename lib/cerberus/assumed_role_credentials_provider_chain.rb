require_relative('../cerberus_client')
require_relative('../cerberus_client/log')
require_relative('exception/no_value_error')
require_relative('exception/no_valid_providers')
require_relative('aws_role_credentials_provider')
require_relative('env_credentials_provider')

module Cerberus

  ##
  # Default credentials provider chain
  ##
  class AssumedRoleCredentialsProviderChain
    def initialize(urlResolver, instanceMdSvcBaseUrl = nil, roleName, roleRegion, roleAccountId)
      vaultBaseUrl = CerberusClient.getUrlFromResolver(urlResolver)

      # return default array of providers
      @providers = [Cerberus::EnvCredentialsProvider.new,
                    Cerberus::AwsRoleCredentialsProvider.new(vaultBaseUrl, instanceMdSvcBaseUrl, roleName, roleRegion, roleAccountId)]
    end


    ##
    # Return the first provider in the default hierarchy that has a valid token
    ##
    def getCredentialsProvider
      @providers.each { |p|
        begin
          # if token is assigned, that's the provider we want.
          # providers must throw NoValueError so that we can fall to the next provider if necessary
          CerberusClient.getCredentialsFromProvider(p)
          return p

        rescue Cerberus::Exception::NoValueError
          next
        end
      }

      # we should have found and returned a valid provider above, else there's a problem
      CerberusClient::Log.instance.error("Could not find a valid provider")
      raise Cerberus::Exception::NoValidProviders.new
    end
  end

end