require_relative('../../lib/cerberus/aws_role_credentials_provider')
require_relative('../fake_url_resolver')
describe Cerberus::AwsRoleCredentialsProvider do

  context "test provider functionality" do

    it "get creds" do
      arcp = Cerberus::AwsRoleCredentialsProvider.new(
          CerberusClient.getUrlFromResolver(FakeUrlResolver.new))
      expect { arcp.getClientToken }.to raise_error(Cerberus::Exception::NoValueError)
    end

    it "have access to role" do
      arcp = Cerberus::AwsRoleCredentialsProvider.new(CerberusClient.getUrlFromResolver(FakeUrlResolver.new))

      expect(arcp.have_access_to_role?("a", nil, nil, nil)).to eq true
      expect(arcp.have_access_to_role?(nil, "x", "y", "z")).to eq true
      expect(arcp.have_access_to_role?(nil, nil, "y", "z")).to eq false
      expect(arcp.have_access_to_role?(nil, "x", nil, "z")).to eq false
      expect(arcp.have_access_to_role?(nil, "x", "y", nil)).to eq false
      expect(arcp.have_access_to_role?(nil, nil, nil, nil)).to eq false
    end

    it "should assume role" do
      arcp = Cerberus::AwsRoleCredentialsProvider.new(CerberusClient.getUrlFromResolver(FakeUrlResolver.new))

      expect(arcp.should_assume_role?("x", "y", "z")).to eq true
      expect(arcp.should_assume_role?("x", "y", nil)).to eq false
      expect(arcp.should_assume_role?("x", nil, "y")).to eq false
      expect(arcp.should_assume_role?(nil, "x", "y")).to eq false
    end

 end # context
end # describe