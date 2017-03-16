require_relative('../../lib/cerberus_client/http')

describe CerberusClient::Http do

  context "Init and test Http" do

    it "initialize" do
      http = CerberusClient::Http.new
      expect(http.instance_of?(CerberusClient::Http)).to eq true
    end


    # Do more here when we have mocking set up

  end # context
end # describe