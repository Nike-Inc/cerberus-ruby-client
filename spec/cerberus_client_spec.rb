require_relative('../lib/cerberus/env_credentials_provider')
require_relative('../lib/cerberus/aws_role_credentials_provider')
require_relative('../lib/cerberus/exception/no_value_error')
require_relative('../lib/cerberus/vault_client')

require('cerberus_client')
require('fake_test_provider_chain')
require('fake_url_resolver')
require('fake_provider')

describe CerberusClient do

  context "validate global functions" do

    it "fail to get credentials from Env provider when env var isn't set" do
      ENV[Cerberus::EnvCredentialsProvider::CERBERUS_VAULT_TOKEN_ENV_KEY] = nil
      envProvider = Cerberus::EnvCredentialsProvider.new
      expect { CerberusClient::getCredentialsFromProvider(envProvider) }.to(
          raise_error(Cerberus::Exception::NoValueError))
    end

    it "get credentials from Env provider with var set" do
      envToken = ENV[Cerberus::EnvCredentialsProvider::CERBERUS_VAULT_TOKEN_ENV_KEY] = "some_token"
      envProvider = Cerberus::EnvCredentialsProvider.new
      expect(CerberusClient::getCredentialsFromProvider(envProvider)).to eq envToken
    end

    it "get credentials from AWS provider" do
      awsProvider = Cerberus::AwsRoleCredentialsProvider.new(
                              CerberusClient.getUrlFromResolver(FakeUrlResolver.new), FAKE_MD_SVC_URL)
      expect { CerberusClient::getCredentialsFromProvider(awsProvider) }.to(
          raise_error(Cerberus::Exception::NoValueError))
    end

    it "get a default vault client" do
      expect(CerberusClient::getDefaultVaultClient().is_a? Cerberus::VaultClient).to eq true
    end

    it "validate vault client init with url resolver supplied" do
      expect(CerberusClient::getVaultClientWithUrlResolver(FakeUrlResolver.new).is_a? Cerberus::VaultClient).to eq true
    end

    it "validate vault client init with url resolver and provider supplied" do
      expect(CerberusClient::getVaultClient(
          FakeUrlResolver.new, FakeTestProviderChain.new).is_a? Cerberus::VaultClient).to eq true
    end

    it "validate vault client provider chain with provider supplied" do
      expect(CerberusClient::getVaultClient(
          FakeUrlResolver.new, FakeTestProviderChain.new).credentialsProvider.is_a? FakeProvider).to eq true
    end

  end # context
end # describe