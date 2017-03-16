require_relative('../../lib/cerberus/env_credentials_provider')

describe Cerberus::EnvCredentialsProvider do

  context "test provider functionality" do

    it "get creds" do
      envToken = ENV[Cerberus::EnvCredentialsProvider::CERBERUS_VAULT_TOKEN_ENV_KEY] = "some_token"
      ecp = Cerberus::EnvCredentialsProvider.new
      expect(ecp.getCredentials).to eq envToken
    end

  end # context
end # describe