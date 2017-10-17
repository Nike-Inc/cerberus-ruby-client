require_relative('../../lib/cerberus_utils/http')

describe CerberusUtils::Http do

  context "Init and test Http" do

    it "initialize" do
      http = CerberusUtils::Http.new
      expect(http.instance_of?(CerberusUtils::Http)).to eq true
    end


    # Do more here when we have mocking set up

  end # context
end # describe