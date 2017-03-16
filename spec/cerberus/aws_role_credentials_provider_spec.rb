require_relative('../../lib/cerberus/aws_role_credentials_provider')

describe Cerberus::AwsRoleCredentialsProvider do

  context "test provider functionality" do

    it "get creds" do
      arcp = Cerberus::AwsRoleCredentialsProvider.new(
          CerberusClient.getUrlFromResolver(FakeUrlResolver.new), FAKE_MD_SVC_URL)
      expect { arcp.getClientToken }.to raise_error(Cerberus::Exception::NoValueError)
    end

  end # context
end # describe