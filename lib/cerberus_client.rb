require_relative('cerberus_utils/version')
require_relative('cerberus/cerberus_client')
require_relative('cerberus/default_url_resolver')
require_relative('cerberus/default_credentials_provider_chain')
require_relative('cerberus/assumed_role_credentials_provider_chain')

module CerberusClient

  ##
  # Get the cerberus client using the default cerberus_url_resolver and default credentialsProviderChain
  ##
  def self.get_default_cerberus_client()
    cerberus_url_resolver = Cerberus::DefaultUrlResolver.new
    return Cerberus::CerberusClient.new(
        cerberus_url_resolver,
        Cerberus::DefaultCredentialsProviderChain.new(cerberus_url_resolver))
  end

  ##
  # Get the cerberus client using the provided cerberus_url_resolver and the credentialsProviderChain
  ##
  def self.get_cerberus_client_with_url_resolver(cerberus_url_resolver)
    return Cerberus::CerberusClient.new(cerberus_url_resolver, Cerberus::DefaultCredentialsProviderChain.new(cerberus_url_resolver))
  end

  ##
  # Get the cerberus client using the provided cerberus_url_resolver and the credentialsProviderChain
  ##
  def self.get_cerberus_client_with_metadata_url(ec2_metadata_service_url)
    cerberus_url_resolver = Cerberus::DefaultUrlResolver.new
    return Cerberus::CerberusClient.new(
        cerberus_url_resolver,
        Cerberus::DefaultCredentialsProviderChain.new(cerberus_url_resolver, nil, ec2_metadata_service_url))
  end

  ##
  # Get the cerberus client using the provided cerberus_url_resolver and the credentialsProviderChain
  ##
  def self.get_cerberus_client(cerberus_url_resolver, credentialsProviderChain)
    return Cerberus::CerberusClient.new(cerberus_url_resolver, credentialsProviderChain)
  end

  def self.get_cerberus_client_for_assumed_role(cerberus_url_resolver, iam_principal_arn, region)
    return Cerberus::CerberusClient.new(
        cerberus_url_resolver,
        Cerberus::AssumedRoleCredentialsProviderChain.new(
            cerberus_url_resolver,
            iam_principal_arn,
            region))
  end

end # CerberusClient module
