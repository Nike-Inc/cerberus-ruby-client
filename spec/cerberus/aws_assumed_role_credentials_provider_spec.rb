require_relative('../../lib/cerberus/aws_assumed_role_credentials_provider')
require_relative('../../lib/cerberus_utils/utils')
require_relative('../fake_url_resolver')
describe Cerberus::AwsAssumeRoleCredentialsProvider do

  context "test provider functionality" do

    it "get creds" do
      arcp = Cerberus::AwsAssumeRoleCredentialsProvider.new(
          FakeUrlResolver.new,
          "arn:aws:iam::000000000000:role/name",
          "us-west-2"
        )
      expect { arcp.get_client_token }.to raise_error(Cerberus::Exception::NoValueError)
    end

 end # context
end # describe