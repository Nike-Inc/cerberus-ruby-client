require_relative('../../lib/cerberus_client/log')
require_relative('../../lib/cerberus_client/default_logger')
require_relative('../fake_logger')
require_relative('../fake_bad_logger')

describe CerberusClient::Log do

  context "Init and test message types" do

    it "Singleton, cannot instantiate a new object" do
      expect { CerberusClient::Log.new }.to raise_error(NoMethodError)
    end

    it "Default implementation should use DefaultLogger" do
      expect(CerberusClient::Log.instance.logProvider.instance_of?(CerberusClient::DefaultLogger)).to eq true
    end

    it "Default logger should log error without exceptions" do
      expect{CerberusClient::Log.instance.error("test")}.to_not raise_error
    end

    it "Default logger should log warning without exceptions" do
      expect{CerberusClient::Log.instance.warn("test")}.to_not raise_error
    end

    it "Default logger should log info without exceptions" do
      expect{CerberusClient::Log.instance.info("test")}.to_not raise_error
    end

    it "Default logger should log debug without exceptions" do
      expect{CerberusClient::Log.instance.debug("test")}.to_not raise_error
    end

    it "Set custom logger" do
      CerberusClient::Log.instance.setLoggingProvider(FakeLogger.new)
      expect(CerberusClient::Log.instance.logProvider.instance_of?(FakeLogger)).to eq true
    end

    it "Custom logger should log error without exceptions" do
      expect{CerberusClient::Log.instance.error("test")}.to_not raise_error
    end

    it "Custom logger should log warning without exceptions" do
      expect{CerberusClient::Log.instance.warn("test")}.to_not raise_error
    end

    it "Custom logger should log info without exceptions" do
      expect{CerberusClient::Log.instance.info("test")}.to_not raise_error
    end

    it "Custom logger should log debug without exceptions" do
      expect{CerberusClient::Log.instance.debug("test")}.to_not raise_error
    end

    it "Set custom bad logger" do
      CerberusClient::Log.instance.setLoggingProvider(FakeBadLogger.new)
      expect(CerberusClient::Log.instance.logProvider.instance_of?(FakeBadLogger)).to eq true
    end

    it "Bad custom logger should throw an exception for missing a method" do
      expect {CerberusClient::Log.instance.error("test")}.to raise_error(NoMethodError)
    end

    it "Set back to default logger" do
      CerberusClient::Log.instance.setLoggingProvider(CerberusClient::DefaultLogger.new)
      expect(CerberusClient::Log.instance.logProvider.instance_of?(CerberusClient::DefaultLogger)).to eq true
    end

  end # context
end # describe