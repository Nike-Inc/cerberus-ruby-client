

module Cerberus

  require_relative('../cerberus_utils/log')
  require_relative('../cerberus_utils/utils')
  require_relative('exception/http_error')
  require_relative('exception/ambiguous_vault_bad_request')
  require_relative('default_credentials_provider_chain')
  require('json')

  ##
  # Client for interacting with the Cerberus API
  ##
  class CerberusClient

    # relative path to the Cerberus secrets API
    SECRET_PATH_PREFIX = "/v1/secret/"
    SECRET_MAP_DATA_KEY = CERBERUS_LIST_DATA_KEY = "data"
    CERBERUS_TOKEN_HEADER_KEY = 'X-Vault-Token'
    CERBERUS_ERRORS_KEY = "errors"
    CERBERUS_PERMISSION_DENIED_ERR = "permission denied"
    CERBERUS_LIST_KEYS_KEY = "keys"
    CERBERUS_LIST_PARAM_KEY = "list"
    SLASH = "/"

    attr_reader :cerberus_base_url
    attr_reader :credentials_provider

    ##
    # Init with the base URL for cerberus
    ##
    def initialize(cerberus_url_resolver, credentials_provider_chain)

      require 'net/https'

      @cerberus_base_url = CerberusUtils::get_url_from_resolver(cerberus_url_resolver)
      @credentials_provider = credentials_provider_chain.get_credentials_provider

    end # initialize

    ##
    # Read operation for a specified path.
    ##
    def read(path)
      begin
        response = read_value_from_cerberus(SECRET_PATH_PREFIX + path)
        CerberusUtils::Log.instance.debug("CerberusClient::read(path) HTTP response: #{response.code}, #{response.message}")
        response.body

      rescue => ex
        CerberusUtils::Log.instance.error("CerberusClient::read(#{path}) unhandled exception trying to read: #{ex.message}")
        raise ex
      end
    end # read

    ##
    # Returns a list of key names at the specified location. Folders are suffixed with /.
    # The input must be a folder; list on a file will return nil
    ##
    def list(path)
      begin
        response = read_value_from_cerberus(SECRET_PATH_PREFIX + path + "?list=true")

        CerberusUtils::Log.instance.debug("CerberusClient::list(#{path}) HTTP response: #{response.code}, #{response.message}")

        json_response_body = JSON.parse(response.body)
        pathList = json_response_body[CERBERUS_LIST_DATA_KEY][CERBERUS_LIST_KEYS_KEY]
        CerberusUtils::Log.instance.debug("CerberusClient::list returning #{pathList.join(", ")} ")
        pathList

      rescue => ex

        # check to see if we threw the Http error with a response object
        response = (ex.instance_of?(Cerberus::Exception::HttpError)) ? ex.response : nil
        if(!response.nil? && response.code.to_i == 404)
          return nil
        end

        CerberusUtils::Log.instance.error("CerberusClient::list(#{path}) unhandled exception trying to read: #{ex.message}")
        raise ex
      end
    end

    private

    ##
    # Do an http request to Cerberus using the relative URI passed in
    ##
    def read_value_from_cerberus(releative_uri)

      url = URI(@cerberus_base_url + releative_uri)
      use_ssl, = ! ("#{@cerberus_base_url}".include? "localhost")

      begin
        headers_map = {CERBERUS_TOKEN_HEADER_KEY => @credentials_provider.get_client_token}
        response = CerberusUtils::Http.new.make_http_call(url, "GET", use_ssl, nil, headers_map)

      rescue Cerberus::Exception::HttpError => ex
        # Since Vault wants to pass back 400 bad request for both paths we don't have access to
        # and paths that don't actually exist at all, I'm sending back a specific error so that implementing clients
        # can at least understand the situation they find themselves in
        #
        # This client could actually work around this problem by first getting a list of all paths we have access to and
        # determining if the path exists in that list.  If not, 404 (which is more appropriate than 400).
        # TODO: implement "list > check for path" work around <-- NOTE:  This is a relatively expensive operation
        if(!ex.response.nil? && (ex.response.code.to_i == 400))
          raise Exception::AmbiguousVaultBadRequest.new
        else
          raise ex
        end

      end

      response

    end # read_value_from_cerberus

    ##
    # Parse out the permission errors json
    ##
    def has_permission_errors?(json_errors_msg)
      begin
        json = JSON.parse(json_errors_msg)
        json[CERBERUS_ERRORS_KEY].each { |err|
          if(err == CERBERUS_PERMISSION_DENIED_ERR)
            return true
          end
        }
      rescue => ex
        CerberusUtils::Log.instance.warn(
            "CerberusClient::hasPermissionErrors? called and exception thrown parsing #{json_errors_msg}: #{ex.message}")
        return false
      end
    end

  end
end
