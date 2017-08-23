require_relative('../../lib/cerberus/aws_principal_credentials_provider')
require_relative('../fake_url_resolver')
describe Cerberus::AwsPrincipalCredentialsProvider do

  context "test provider functionality" do

    it "get creds" do
      arcp = Cerberus::AwsPrincipalCredentialsProvider.new(
          CerberusClient.getUrlFromResolver(FakeUrlResolver.new))
      expect { arcp.getClientToken }.to raise_error(Cerberus::Exception::NoValueError)
    end

 end # context
end # describe
