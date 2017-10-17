require_relative('../../lib/cerberus/cerberus_client')
require_relative('../fake_test_provider_chain')

##
# This is an acceptance test to validate that the client is working properly
#
# REQUIRES VALID CERBERUS ENVIRONMENT VAR TOKEN!
# Which can be acquired using this script:
# https://raw.githubusercontent.com/Nike-Inc/cerberus/master/docs/user-guide/cerberus-token.sh
# It does NOT run by default using rspec
#
# export CERBERUS_CLIENT_ACCEPTANCE_TESTS=true then run this test using rspec to validate
#
# This test has several assumptions:
#   1) That the cerberus token set in the environment variable
#       EnvCredentialsProvider::CERBERUS_TOKEN_ENV_KEY is valid
#       Use cerberus-token.sh linked above and export CERBERUS_TOKEN
#   2) That the Cerberus base url is set in the environment variable
#       DefaultUrlResolver::CERBERUS_URL_ENV_KEY is valid and the token set above has access to it
#       Use cerberus-token.sh linked above and export CERBERUS_HOST
#   3) That the "path" variable used exists and is accessible by the cerberus token
#       Set using FULL_PATH - You will likely need to change this to match YOUR SDB setup
#   4) That the "key" and "value" exist in Cerberus
#       Set using EXISTING_KEY & EXISTING_KEY_VALUE - You will likely need to change this to match YOUR SDB setup
#
# IF YOU ARE GETTING Cerberus::Exception::AmbiguousVaultBadRequest when running the tests, it is likely that the
# path or key values are incorrect!  Make sure they match what you see in CMS
##

if ENV["CERBERUS_CLIENT_ACCEPTANCE_TESTS"] == 'true'

  describe Cerberus::CerberusClient do

    context "acceptance tests" do

      SDB_PATH = "app/sdb-name"  # path to SDB only
      SECRET_NAME = "secret"  # node name
      EXISTING_KEY = "key"  # secret key
      EXISTING_KEY_VALUE = "value"  # secret value
      # for negative tests
      NONEXISTENT_KEY = "non-existent-key"
      NONEXISTENT_PATH = "non-existent-path"

      it "should throw AmbiguousVaultBadRequest for non-existent path" do
        cerberus_client = CerberusClient::get_cerberus_client_with_metadata_url(nil)
        expect { cerberus_client.read(NONEXISTENT_PATH) }.to raise_error(Cerberus::Exception::HttpError)
      end

      it "list keys for an existing path" do
        path = "#{SDB_PATH}/#{SECRET_NAME}"
        cerberus_client = CerberusClient::get_cerberus_client_with_metadata_url(nil)
        expect(cerberus_client.list(path).include?(SECRET_NAME)).to eq true
      end

      it "list keys for an non-existent path" do
        path = "#{SDB_PATH}/#{NONEXISTENT_PATH}"
        cerberus_client = CerberusClient::get_cerberus_client_with_metadata_url(nil)
        expect(cerberus_client.list(path).nil?).to eq true
      end

      it "list keys for an non-existent root path" do
        path = ""
        cerberus_client = CerberusClient::get_cerberus_client_with_metadata_url(nil)
        expect{cerberus_client.list(path)}.to raise_error(Cerberus::Exception::HttpError)
      end

      it "list keys for a existing path including key" do
        path = "#{SDB_PATH}/#{SECRET_NAME}"
        cerberus_client = CerberusClient::get_cerberus_client_with_metadata_url(nil)
        expect(cerberus_client.list(path).nil?).to eq true
      end
    end
  end
end
