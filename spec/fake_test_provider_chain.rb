require('fake_provider')
class FakeTestProviderChain
  def get_credentials_provider
    return FakeProvider.new
  end
end