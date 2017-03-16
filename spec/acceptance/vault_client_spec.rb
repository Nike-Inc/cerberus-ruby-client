require_relative('../../lib/cerberus/vault_client')
require_relative('../fake_test_provider_chain')

if ENV["VAULT_ACCEPTANCE_TESTS"] == 'true'

  describe Cerberus::VaultClient do

    context "acceptance tests" do

      ##
      # These tests share several of these assumptions:
      #   1) That the vault token set in the environment variable
      #       EnvCredentialsProvider::CERBERUS_VAULT_TOKEN_ENV_KEY is valid
      #   2) That the Cerberus base url is set in the environment variable
      #       DefaultUrlResolver::CERBERUS_VAULT_URL_ENV_KEY is valid and the token set above has access to it
      #   3) That the "path" variable used exists and is accessible by the vault token
      #   4) That the "key" and "value" exist and they are equal to "test"
      ##
      it "should read once the cerberus token env var is set" do
        path = "app/artemis-events/local"
        key = "testkey"
        value = "test"
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.readKey(path, key)).to eq value
      end

      it "should return nil for existing path but non-existent key" do
        path = "app/artemis-events/local"
        key = "foo"
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.readKey(path, key).nil?).to eq true
      end

      it "should throw AmbiguousVaultBadRequest for non-existent path" do
        path = "thequickfoxdoesntlie"
        vaultClient = CerberusClient::getDefaultVaultClient
        expect { vaultClient.read(path) }.to raise_error(Cerberus::Exception::AmbiguousVaultBadRequest)
      end

      it "list keys for an existing path" do
        path = "app/artemis-events/"
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.list(path).include?("local")).to eq true
      end

      it "list keys for an non-existent path" do
        path = "app/artemis-events/thequickfoxdoesntlie"
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.list(path).nil?).to eq true
      end

      it "list keys for an non-existent root path" do
        path = ""
        vaultClient = CerberusClient::getDefaultVaultClient
        expect{vaultClient.list(path)}.to raise_error(Cerberus::Exception::AmbiguousVaultBadRequest)
      end

      it "list keys for a existing path including key" do
        path = "app/artemis-events/local/test"
        vaultClient = CerberusClient::getDefaultVaultClient
        expect(vaultClient.list(path).nil?).to eq true
      end

      it "should recursively describe a path" do
        path = "app/artemis-events/"
        vaultClient = CerberusClient::getDefaultVaultClient
        desc = vaultClient.describe!(path)
        expect(desc.is_a?(Hash)).to eq true
        expect(desc.length).not_to equal(0)
      end

      it "should recursively describe an 'end' path" do
        path = "app/artemis-events/local"
        vaultClient = CerberusClient::getDefaultVaultClient
        desc = vaultClient.describe!(path)
        expect(desc.length).to eq 1
      end

      it "should throw an http exception for missing path" do
        path = "app/artemis-events/foo"
        vaultClient = CerberusClient::getDefaultVaultClient
        expect{vaultClient.describe!(path)}.to raise_error(Cerberus::Exception::HttpError)
      end
    end
  end
end
