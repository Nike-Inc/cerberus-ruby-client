module Cerberus
  class CerberusAuthInfo
    attr_reader :iam_principal_arn
    attr_reader :region
    attr_reader :credentials

    def initialize(iam_principal_arn, region, credentials = nil)
      @iam_principal_arn = iam_principal_arn
      @region = region
      @credentials = credentials
    end
  end
end