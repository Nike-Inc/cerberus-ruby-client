

module Cerberus

  require_relative('../cerberus_client/log')
  require_relative('exception/http_error')
  require_relative('exception/ambiguous_vault_bad_request')
  require_relative('default_credentials_provider_chain')
  require('json')

  ##
  # Client for interacting with the Vault API
  ##
  class VaultClient

    # relative path to the Vault secrets API
    SECRET_PATH_PREFIX = "/v1/secret/"
    SECRET_MAP_DATA_KEY = VAULT_LIST_DATA_KEY = "data"
    VAULT_TOKEN_HEADER_KEY = 'X-Vault-Token'
    VAULT_ERRORS_KEY = "errors"
    VAULT_PERMISSION_DENIED_ERR = "permission denied"
    VAULT_LIST_KEYS_KEY = "keys"
    VAULT_LIST_PARAM_KEY = "list"
    SLASH = "/"

    attr_reader :vaultBaseUrl
    attr_reader :credentialsProvider

    ##
    # Init with the base URL for vault
    ##
    def initialize(urlResolver, credentialsProviderChain)

      require 'net/https'

      @vaultBaseUrl = CerberusClient.getUrlFromResolver(urlResolver)
      @credentialsProvider = credentialsProviderChain.getCredentialsProvider

    end # initialize

    ##
    # Read operation for a specified path.
    ##
    def read(path)
      begin
        response = doVaultHttpGet(SECRET_PATH_PREFIX + path)
        CerberusClient::Log.instance.debug("VaultClient::read(path) HTTP response: #{response.code}, #{response.message}")
        response.body

      rescue => ex
        CerberusClient::Log.instance.error("VaultClient::read(#{path}) unhandled exception trying to read: #{ex.message}")
        raise ex
      end
    end # read

    ##
    # Read operation for a specified path.
    ##
    def readKey(path, key)
      begin
        CerberusClient::Log.instance.error("VaultClient::read(#{path}, #{key})")

        readPathAndIterateOnDataWithProc(path, &(Proc.new { |k, v| if(key == k); return v; end }) )

        # else, we didn't find it
        return nil

      rescue => ex
        CerberusClient::Log.instance.error("VaultClient::read(#{path}, #{key}) unhandled exception trying to read: #{ex.message}")
        raise ex
      end
    end

    ##
    # Returns a list of key names at the specified location. Folders are suffixed with /.
    # The input must be a folder; list on a file will return nil
    ##
    def list(path)
      begin
        response = doVaultHttpGet(SECRET_PATH_PREFIX + path + "?list=true")

        CerberusClient::Log.instance.debug("VaultClient::list(#{path}) HTTP response: #{response.code}, #{response.message}")

        jsonResonseBody = JSON.parse(response.body)
        pathList = jsonResonseBody[VAULT_LIST_DATA_KEY][VAULT_LIST_KEYS_KEY]
        CerberusClient::Log.instance.debug("VaultClient::list returning #{pathList.join(", ")} ")
        pathList

      rescue => ex

        # check to see if we threw the Http error with a response object
        response = (ex.instance_of?(Cerberus::Exception::HttpError)) ? ex.response : nil
        if(!response.nil? && response.code.to_i == 404)
          return nil
        end

        CerberusClient::Log.instance.error("VaultClient::list(#{path}) unhandled exception trying to read: #{ex.message}")
        raise ex
      end
    end

    ##
    # This is potentially an expensive operation depending on the depth of the tree we're trying to parse
    # It recursively walks 'path' and returns a hash of all child [path] => [array of keys] found under 'path'
    # if 'path' is a folder, it must have a trailing slash ('/').  If 'path' is an "end node" or "vault file", then it
    # should not have a trailing slash ('/')
    ##
    def describe!(path, resultHash = nil)

      CerberusClient::Log.instance.debug("VaultClient::describe!(#{path})")

      if(resultHash == nil)
        resultHash = Hash.new()
      end

      curChildren = list(path)

      # if curChildren is nil, it's possible there are no children or that we don't have access
      # It's also possible it is the "end" of the path... what Vault calls "the file"
      # in that case, we should send back the keys in that path so give it a shot
      if(curChildren.nil?)
        resultHash[path] = Array.new
        readPathAndIterateOnDataWithProc(path, &(Proc.new { |key, value| resultHash[path] << key }) )
        return resultHash
      end

      curChildren.each { |childNode|
        curLocation = path + childNode
        # if childNode ends with '/' then we have a directory we need to call into
        if(childNode.end_with?(SLASH))
          describe!(curLocation, resultHash)
        else # it is a "directory" that contains keys
          resultHash[curLocation] = Array.new
          readPathAndIterateOnDataWithProc(curLocation, &(Proc.new { |key, value| resultHash[curLocation] << key }) )
        end
      }
      return resultHash
    end

    private


    ##
    #  Attempts to execute the proc passed in on every key, value located in the 'data' element read at 'path'
    ##
    def readPathAndIterateOnDataWithProc(path, &p)
      jsonResponseBody = JSON.parse(read(path))
      jsonResponseBody[VAULT_LIST_DATA_KEY].each { |dataMapKey, dataMapValue|
        p.call(dataMapKey, dataMapValue)
      }
    end

    ##
    # Do an http request to Vault using the relative URI passed in
    ##
    def doVaultHttpGet(relativeUri)

      url = URI(@vaultBaseUrl + relativeUri)
      useSSL = ! ("#{@vaultBaseUrl}".include? "localhost")

      begin
        response = CerberusClient::Http.new.doHttp(url,
                                                 'GET', useSSL, nil,
                                                 {VAULT_TOKEN_HEADER_KEY =>
                                                      CerberusClient.getCredentialsFromProvider(@credentialsProvider)})

      rescue Cerberus::Exception::HttpError => ex
        # Since Vault wants to pass back 400 bad request for both paths we don't have access to
        # and paths that don't actually exist at all, I'm sending back a specific error so that implementing clients
        # can at least understand the situation they find themselves in
        #
        # This client could actually work around this problem by first getting a list of all paths we have access to and
        # determining if the path exists in that list.  If not, 404 (which is more appropriate than 400).
        # TODO: implement "list > check for path" work around <-- NOTE:  This is a relatively expensive operation

        if(!ex.response.nil? && (ex.response.code.to_i == 400) && (hasPermissionErrors?(ex.response.body)))
          raise Exception::AmbiguousVaultBadRequest.new
        else
          raise ex
        end

      end

      response

    end # doVaultHttp

    ##
    # Parse out the permission errors json
    ##
    def hasPermissionErrors?(jsonErrorsMsg)
      begin
        json = JSON.parse(jsonErrorsMsg)
        json[VAULT_ERRORS_KEY].each { |err|
          if(err == VAULT_PERMISSION_DENIED_ERR)
            return true
          end
        }
      rescue => ex
        CerberusClient::Log.instance.warn(
            "VaultClient::hasPermissionErrors? called and exception thrown parsing #{jsonErrorsMsg}: #{ex.message}")
        return false
      end
    end

  end
end
