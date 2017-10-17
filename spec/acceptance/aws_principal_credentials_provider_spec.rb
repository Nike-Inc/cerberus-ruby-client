require_relative('../../lib/cerberus/aws_principal_credentials_provider')
require_relative('../../lib/cerberus/default_url_resolver')
require_relative('../../lib/cerberus/exception/no_value_error')
require_relative('../fake_test_provider_chain')

##
# This is an acceptance test to validate that the client is working properly
# ON AN EC2 INSTANCE - it does NOT run by default using rspec
#
# export AWS_CREDS_PROVIDER_TEST=true then run this test using rspec to validate
#
# This test has several assumptions:
#   1) Assumes HardcodedTestingUrlResolver resolves to a valid Cerberus instance
#   2) That it is running on an AWS instance with access to the AWS metadata service
#   3) That the instance has a role assigned to it in an account that has been setup in Cerberus
#   4) That the bucket in Cerberus has the path and value being tested for in the "read" acceptance test
#        You will likely need to change this to match YOUR SDB setup
##

if ENV["AWS_CREDS_PROVIDER_TEST"] == 'true'

  describe Cerberus::AwsPrincipalCredentialsProvider do

    context "test get_client_token" do
      it "should try to get credentials" do
        awsProvider = Cerberus::AwsPrincipalCredentialsProvider.new(Cerberus::DefaultUrlResolver.new)

        expect(awsProvider.get_client_token.is_a? String).to eq true
      end
    end

    context "read a value acceptance test" do

      it "should read from Cerberus using AWS role auth" do

        path = "app/sdb-name/secret"
        key = "key"
        value = "value"

        cerberus_client = CerberusClient::get_default_cerberus_client()

        expect(cerberus_client.read(path)["#{key}"]).to eq value
      end
    end

  end
end
