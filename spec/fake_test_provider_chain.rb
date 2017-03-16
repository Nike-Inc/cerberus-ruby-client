require('fake_provider')
class FakeTestProviderChain
  def getCredentialsProvider
    return FakeProvider.new
  end
end