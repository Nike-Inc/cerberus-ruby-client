require_relative('../lib/cerberus/env_credentials_provider')
require_relative('../lib/cerberus/aws_assumed_role_credentials_provider')
require_relative('../lib/cerberus/exception/no_value_error')
require_relative('../lib/cerberus/cerberus_client')
require_relative('../lib/cerberus_utils/utils')

require('cerberus_client')
require('fake_test_provider_chain')
require('fake_url_resolver')
require('fake_provider')

describe CerberusClient do

  context "validate global functions" do

    it "fail to get credentials from Env provider when env var isn't set" do
      ENV[Cerberus::EnvCredentialsProvider::CERBERUS_TOKEN_ENV_KEY] = nil
      envProvider = Cerberus::EnvCredentialsProvider.new
      expect { CerberusUtils::get_credentials_from_provider(envProvider) }.to(
          raise_error(Cerberus::Exception::NoValueError))
    end

    it "get credentials from Env provider with var set" do
      envToken = ENV[Cerberus::EnvCredentialsProvider::CERBERUS_TOKEN_ENV_KEY] = "some_token"
      envProvider = Cerberus::EnvCredentialsProvider.new
      expect(CerberusUtils::get_credentials_from_provider(envProvider)).to eq envToken
    end

    it "get credentials from AWS provider" do
      awsProvider = Cerberus::AwsAssumeRoleCredentialsProvider.new(
          FakeUrlResolver.new,
          "arn:aws:iam::000000000000:role/name",
          "us-west-2")
      expect { CerberusUtils::get_credentials_from_provider(awsProvider) }.to(
          raise_error(Cerberus::Exception::NoValueError))
    end

    it "validate cerberus client init with url resolver and provider supplied" do
      expect(CerberusClient::get_cerberus_client(
          FakeUrlResolver.new, FakeTestProviderChain.new).is_a? Cerberus::CerberusClient).to eq true
    end

    it "validate cerberus client provider chain with provider supplied" do
      expect(CerberusClient::get_cerberus_client(
          FakeUrlResolver.new, FakeTestProviderChain.new).credentials_provider.is_a? FakeProvider).to eq true
    end

  end # context
end # describe