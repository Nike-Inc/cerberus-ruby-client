require_relative('../../lib/cerberus/default_url_resolver')

describe Cerberus::DefaultUrlResolver do

  context "test url resolver functionality" do

    it "get url" do
      envUrl = ENV[Cerberus::DefaultUrlResolver::CERBERUS_VAULT_URL_ENV_KEY] = "some_url"
      dur = Cerberus::DefaultUrlResolver.new
      expect(dur.getUrl).to eq envUrl
    end

  end
end