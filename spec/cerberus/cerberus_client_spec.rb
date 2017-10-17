require_relative('../../lib/cerberus/cerberus_client')
require_relative('../fake_test_provider_chain')
require_relative('../fake_provider')
require_relative('../fake_url_resolver')

describe Cerberus::CerberusClient do

  context "init properly" do

    it "with url_resolver, validate url set" do
      fr = FakeUrlResolver.new
      expect { Cerberus::CerberusClient.new(
          fr,
          Cerberus::DefaultCredentialsProviderChain.new(fr, "us-west-2", nil))
      }.to raise_error(Cerberus::Exception::NoValidProviders)
    end

    it "with base url and creds provider" do
      fr = FakeUrlResolver.new
      cerb_client = Cerberus::CerberusClient.new(fr, FakeTestProviderChain.new)
      expect(cerb_client.credentials_provider.is_a? FakeProvider).to eq true
      expect(cerb_client.cerberus_base_url).to eq fr.get_url
    end


  end # context
end # describe