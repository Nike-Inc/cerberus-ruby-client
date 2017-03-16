module Cerberus
  class AwsRoleInfo
    attr_reader :name
    attr_reader :region
    attr_reader :credentials
    attr_reader :account_id

    def initialize(name, region, account_id, credentials = nil)
      @name = name
      @region = region
      @account_id = account_id
      @credentials = credentials
    end
  end
end