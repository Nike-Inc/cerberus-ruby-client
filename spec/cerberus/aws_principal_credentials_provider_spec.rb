require_relative('../../lib/cerberus/aws_principal_credentials_provider')
require_relative('../../lib/cerberus_utils/utils')
require_relative('../fake_url_resolver')
describe Cerberus::AwsPrincipalCredentialsProvider do

  context "test provider functionality" do

    it "get creds" do
      arcp = Cerberus::AwsPrincipalCredentialsProvider.new(
          FakeUrlResolver.new,
          "us-west-2",
          nil)
      expect { arcp.get_client_token }.to raise_error(Cerberus::Exception::NoValueError)
    end

 end # context
end # describe
