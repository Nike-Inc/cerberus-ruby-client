
module Cerberus

  require_relative('exception/no_value_error')

  ##
  # The default Cerberus URL resolver - looks for #{CERBERUS_URL_ENV_KEY} in env vars
  ##
  class DefaultUrlResolver

    CERBERUS_URL_ENV_KEY = "CERBERUS_ADDR"

    ##
    # Look for the cerberus url in the env var
    ##
    def get_url
      url_option = ENV[CERBERUS_URL_ENV_KEY]

      if(url_option != nil)
        return url_option
      else
        raise Cerberus::Exception::NoValueError
      end
    end
  end
end