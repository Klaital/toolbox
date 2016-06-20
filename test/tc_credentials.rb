require 'test/unit'
require_relative '../lib/credentials.rb'

class TcCredentials < Test::Unit::TestCase
  def test_load_google
     # Ensure that the relevant Google API keys/credentials are loaded
     assert_not_nil(CREDENTIALS['google'], 'Google top-level not loaded')
     assert_not_nil(CREDENTIALS['google']['geocode_api'], 'Google Geocode API set not loaded')
     assert_not_nil(CREDENTIALS['google']['geocode_api']['key'], 'Google Geocode API key not loaded')
  end
end
