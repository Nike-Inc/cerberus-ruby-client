require_relative('../../lib/cerberus/vault_client')
require_relative('../fake_test_provider_chain')

##
# This is an acceptance test to validate that the client is working properly
#
# REQUIRES VALID CERBERUS ENVIRONMENT VAR TOKEN!
# Which can be acquired using this script:
# https://raw.githubusercontent.com/Nike-Inc/cerberus/master/docs/user-guide/cerberus-token.sh
# It does NOT run by default using rspec
#
# export VAULT_ACCEPTANCE_TESTS=true then run this test using rspec to validate
#
# This test has several assumptions:
#   1) That the vault token set in the environment variable
#       EnvCredentialsProvider::CERBERUS_VAULT_TOKEN_ENV_KEY is valid
#       Use cerberus-token.sh linked above and export CERBERUS_TOKEN
#   2) That the Cerberus base url is set in the environment variable
#       DefaultUrlResolver::CERBERUS_VAULT_URL_ENV_KEY is valid and the token set above has access to it
#       Use cerberus-token.sh linked above and export CERBERUS_HOST
#   3) That the "path" variable used exists and is accessible by the vault token
#       Set using DEFAULT_PATH - You will likely need to change this to match YOUR SDB setup
#   4) That the "key" and "value" exist in Cerberus
#       Set using DEFAULT_KEY & DEFAULT_VALUE - You will likely need to change this to match YOUR SDB setup
#
# IF YOU ARE GETTING Cerberus::Exception::AmbiguousVaultBadRequest when running the tests, it is likely that the
# path or key values are incorrect!  Make sure they match what you see in CMS
##

if ENV["VAULT_ACCEPTANCE_TESTS"] == 'true'

  describe Cerberus::VaultClient do

    context "acceptance tests" do

      DEFAULT_PATH_PART1 = "app/your-app/"
      DEFAULT_PATH_PART2 = "local"
      DEFAULT_PATH = DEFAULT_PATH_PART1 + DEFAULT_PATH_PART2
      DEFAULT_KEY = "testkey"
      DEFAULT_VALUE = "test"
      # for negative tests
      NONEXISTENT_KEY = "non-existent-key"
      NONEXISTENT_PATH = "thequickfoxdoesntlie"

      ##
      it "should read once the cerberus token env var is set" do
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.readKey(DEFAULT_PATH, DEFAULT_KEY)).to eq DEFAULT_VALUE
      end

      it "should return nil for existing path but non-existent key" do
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.readKey(DEFAULT_PATH, NONEXISTENT_KEY).nil?).to eq true
      end

      it "should throw AmbiguousVaultBadRequest for non-existent path" do
        vaultClient = CerberusClient::getDefaultVaultClient
        expect { vaultClient.read(NONEXISTENT_PATH) }.to raise_error(Cerberus::Exception::AmbiguousVaultBadRequest)
      end

      it "list keys for an existing path" do
        path = DEFAULT_PATH_PART1
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.list(path).include?(DEFAULT_PATH_PART2)).to eq true
      end

      it "list keys for an non-existent path" do
        path = DEFAULT_PATH_PART1 + NONEXISTENT_PATH
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.list(path).nil?).to eq true
      end

      it "list keys for an non-existent root path" do
        path = ""
        vaultClient = CerberusClient::getDefaultVaultClient
        expect{vaultClient.list(path)}.to raise_error(Cerberus::Exception::AmbiguousVaultBadRequest)
      end

      it "list keys for a existing path including key" do
        path = DEFAULT_PATH + "/" + DEFAULT_KEY
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.list(path).nil?).to eq true
      end

      it "should recursively describe a path" do
        path = DEFAULT_PATH_PART1
        vaultClient = CerberusClient::getDefaultVaultClient
        desc = vaultClient.describe!(path)
        expect(desc.is_a?(Hash)).to eq true
        expect(desc.length).not_to equal(0)
      end

      it "should recursively describe an 'end' path" do
        vaultClient = CerberusClient::getDefaultVaultClient
        desc = vaultClient.describe!(DEFAULT_PATH)
        expect(desc.length).to eq 1
      end

      it "should throw an http exception for missing path" do
        path = DEFAULT_PATH_PART1 + "/" + NONEXISTENT_PATH
        vaultClient = CerberusClient::getDefaultVaultClient
        expect{vaultClient.describe!(path)}.to raise_error(Cerberus::Exception::HttpError)
      end
    end
  end
end
