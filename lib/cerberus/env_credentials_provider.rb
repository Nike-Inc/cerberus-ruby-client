

module Cerberus

  require_relative('exception/no_value_error')

  ##
  # The Environment variable credentials provider - looks for #{CERBERUS_TOKEN_ENV_KEY} in env vars
  ##
  class EnvCredentialsProvider

    CERBERUS_TOKEN_ENV_KEY = "CERBERUS_TOKEN"

    ##
    # Look for the cerberus token in the env var
    ##
    def get_client_token

      tokenOption = ENV[CERBERUS_TOKEN_ENV_KEY]

      if(tokenOption != nil)
        return tokenOption
      else
        raise Cerberus::Exception::NoValueError
      end
    end

  end
end