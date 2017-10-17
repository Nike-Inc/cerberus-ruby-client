require_relative('../../lib/cerberus_utils/log')
require_relative('../../lib/cerberus_utils/default_logger')
require_relative('../fake_logger')
require_relative('../fake_bad_logger')

describe CerberusUtils::Log do

  context "Init and test message types" do

    it "Singleton, cannot instantiate a new object" do
      expect { CerberusUtils::Log.new }.to raise_error(NoMethodError)
    end

    it "Default implementation should use DefaultLogger" do
      expect(CerberusUtils::Log.instance.logProvider.instance_of?(CerberusUtils::DefaultLogger)).to eq true
    end

    it "Default logger should log error without exceptions" do
      expect{CerberusUtils::Log.instance.error("test")}.to_not raise_error
    end

    it "Default logger should log warning without exceptions" do
      expect{CerberusUtils::Log.instance.warn("test")}.to_not raise_error
    end

    it "Default logger should log info without exceptions" do
      expect{CerberusUtils::Log.instance.info("test")}.to_not raise_error
    end

    it "Default logger should log debug without exceptions" do
      expect{CerberusUtils::Log.instance.debug("test")}.to_not raise_error
    end

    it "Set custom logger" do
      CerberusUtils::Log.instance.setLoggingProvider(FakeLogger.new)
      expect(CerberusUtils::Log.instance.logProvider.instance_of?(FakeLogger)).to eq true
    end

    it "Custom logger should log error without exceptions" do
      expect{CerberusUtils::Log.instance.error("test")}.to_not raise_error
    end

    it "Custom logger should log warning without exceptions" do
      expect{CerberusUtils::Log.instance.warn("test")}.to_not raise_error
    end

    it "Custom logger should log info without exceptions" do
      expect{CerberusUtils::Log.instance.info("test")}.to_not raise_error
    end

    it "Custom logger should log debug without exceptions" do
      expect{CerberusUtils::Log.instance.debug("test")}.to_not raise_error
    end

    it "Set custom bad logger" do
      CerberusUtils::Log.instance.setLoggingProvider(FakeBadLogger.new)
      expect(CerberusUtils::Log.instance.logProvider.instance_of?(FakeBadLogger)).to eq true
    end

    it "Bad custom logger should throw an exception for missing a method" do
      expect {CerberusUtils::Log.instance.error("test")}.to raise_error(NoMethodError)
    end

    it "Set back to default logger" do
      CerberusUtils::Log.instance.setLoggingProvider(CerberusUtils::DefaultLogger.new)
      expect(CerberusUtils::Log.instance.logProvider.instance_of?(CerberusUtils::DefaultLogger)).to eq true
    end

  end # context
end # describe