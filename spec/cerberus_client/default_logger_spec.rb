require_relative('../../lib/cerberus_client/default_logger')

describe CerberusClient::DefaultLogger do

  context "Init and test message types" do

    it "initialize" do
      dl = CerberusClient::DefaultLogger.new
      expect(dl.instance_of?(CerberusClient::DefaultLogger)).to eq true
    end

    it "log error without exceptions" do
      dl = CerberusClient::DefaultLogger.new
      expect{dl.error("test")}.to_not raise_error
    end

    it "log warning without exceptions" do
      dl = CerberusClient::DefaultLogger.new
      expect{dl.warn("test")}.to_not raise_error
    end

    it "log info without exceptions" do
      dl = CerberusClient::DefaultLogger.new
      expect{dl.info("test")}.to_not raise_error
    end

    it "log debug without exceptions" do
      dl = CerberusClient::DefaultLogger.new
      expect{dl.debug("test")}.to_not raise_error
    end

  end # context
end # describe