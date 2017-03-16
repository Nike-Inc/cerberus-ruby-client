
module Cerberus

  require_relative('exception/no_value_error')

  ##
  # The default Vault URL resolver - looks for #{CERBERUS_VAULT_URL_ENV_KEY} in env vars
  ##
  class DefaultUrlResolver

    CERBERUS_VAULT_URL_ENV_KEY = "CERBERUS_ADDR"

    ##
    # Look for the vault url in the env var
    ##
    def getUrl
      urlOption = ENV[CERBERUS_VAULT_URL_ENV_KEY]

      if(urlOption != nil)
        return urlOption
      else
        raise Cerberus::Exception::NoValueError
      end
    end
  end
end