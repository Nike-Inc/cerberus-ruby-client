require_relative('cerberus_client/version')
require_relative('cerberus/vault_client')
require_relative('cerberus/default_url_resolver')
require_relative('cerberus/default_credentials_provider_chain')
require_relative('cerberus/assumed_role_credentials_provider_chain')

module CerberusClient

  ##
  # Get the vault client using the default vaultUrlResolver and default credentialsProviderChain
  ##
  def self.getDefaultVaultClient()
    vaultUrlResolver = Cerberus::DefaultUrlResolver.new
    return Cerberus::VaultClient.new(vaultUrlResolver, 
                                     Cerberus::DefaultCredentialsProviderChain.new(vaultUrlResolver))
  end

  ##
  # Get the vault client using the provided vaultUrlResolver and the credentialsProviderChain
  ##
  def self.getVaultClientWithUrlResolver(vaultUrlResolver)
     return Cerberus::VaultClient.new(vaultUrlResolver, Cerberus::DefaultCredentialsProviderChain.new(vaultUrlResolver))
  end

  ##
  # Get the vault client using the provided vaultUrlResolver and the credentialsProviderChain
  ##
  def self.getVaultClient(vaultUrlResolver, credentialsProviderChain)
    return Cerberus::VaultClient.new(vaultUrlResolver, credentialsProviderChain)
  end

  def self.getVaultClientForAssumedRole(vaultUrlResolver, roleName, roleRegion, roleAccountId)
    return Cerberus::VaultClient.new(vaultUrlResolver, Cerberus::AssumedRoleCredentialsProviderChain.new(vaultUrlResolver,
                                                                                                     nil,
                                                                                                     roleName,
                                                                                                     roleRegion,
                                                                                                     roleAccountId))
  end


  ##
  # Get credentials from implementing credentialProvider
  ##
  def self.getCredentialsFromProvider(credentialProvider)
    return credentialProvider.getClientToken
  end

  ##
  # Get credentials provider from chain implementing get getCredentialsProvider
  ##
  def self.getCredentialsProviderFromChain(credentialProviderChain)
    return credentialProviderChain.getCredentialsProvider
  end

  ##
  # Get url from implementing url resolver
  ##
  def self.getUrlFromResolver(vaultUrlResolver)
    return vaultUrlResolver.getUrl
  end

end # CerberusClient module
