require_relative('../../lib/cerberus/cerberus_client_token')

describe Cerberus::CerberusClientToken do

  context "test expiration time" do

    TOKEN = "some-token"
    POLICIES = ["policy1", "policy2"]
    ONE_SECOND = 1
    TWO_SECONDS = 2

    it "create with expire time set" do
      creds = Cerberus::CerberusClientToken.new(TOKEN, TWO_SECONDS, POLICIES)
      expect(creds.cacheLifetimeSec).to eq TWO_SECONDS
    end

    it "test for expiration - should be expired" do
      creds = Cerberus::CerberusClientToken.new(TOKEN, ONE_SECOND, POLICIES)
      sleep(ONE_SECOND + ONE_SECOND)
      expect(creds.expired?).to eq true
    end

    it "test for expiration - should not be expired" do
      creds = Cerberus::CerberusClientToken.new(TOKEN, TWO_SECONDS, POLICIES)
      sleep(TWO_SECONDS - ONE_SECOND)
      expect(creds.expired?).to eq false
    end

  end # context
end # describe