module CerberusUtils
  
  ##
  # Get credentials from implementing credential_provider
  ##
  def self.get_credentials_from_provider(credential_provider)
    return credential_provider.get_client_token
  end

  ##
  # Get credentials provider from chain implementing get get_credentials_provider
  ##
  def self.get_credentials_provider_from_chain(credential_provider_chain)
    return credential_provider_chain.get_credentials_provider
  end

  ##
  # Get url from implementing url resolver
  ##
  def self.get_url_from_resolver(cerberus_url_resolver)
    return cerberus_url_resolver.get_url
  end
  
end