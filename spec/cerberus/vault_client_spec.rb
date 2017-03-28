require_relative('../../lib/cerberus/vault_client')
require_relative('../fake_test_provider_chain')
require_relative('../fake_provider')
require_relative('../fake_url_resolver')

describe Cerberus::VaultClient do

  context "init properly" do

    it "with urlResolver, validate url set" do
      fr = FakeUrlResolver.new
      vc = Cerberus::VaultClient.new(fr, Cerberus::DefaultCredentialsProviderChain.new(fr))
      expect(vc.vaultBaseUrl).to eq fr.getUrl
    end

    it "with base url and creds provider" do
      vc = Cerberus::VaultClient.new(FakeUrlResolver.new, FakeTestProviderChain.new)
      expect(vc.credentialsProvider.is_a? FakeProvider).to eq true
    end


  end # context
end # describe