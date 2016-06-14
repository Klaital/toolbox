# geocoder.rb
# A library to facilitate API calls to the Google Geocoding Web Service
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'logger'


GOOGLE_API_KEY = 'AIzaSyBbQQxvFqayNuN_nE71m0Z7iUOSUigMZV4' # Enter your API key here (https://developers.google.com/maps/documentation/geocoding/start#get-a-key)

class Geocoder
  def initialize(opts={})
    @api_key = opts[:api_key] || GOOGLE_API_KEY
    @log = opts[:log] || Logger.new($stdout)
    @api_url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$ADDRESS&key=$API_KEY'
  end

  # Execute the Google Geocache API call, and return the raw result.
  # TODO: refine the response such that it is just the geocode, not a JSON doc.
  def query_google(address)
    # Substitute in the requested address to encode, plus our Google API key for the geocoding webservice
    endpoint = @api_url.gsub('$ADDRESS', Geocoder.encode_address(address)).gsub('$API_KEY', @api_key)
    uri = URI(endpoint)

    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https') do |http|
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new uri
      @log.info("Looking up '#{address}' via '#{endpoint}'")
      start_time = Time.now
      response = http.request(request)
      @log.info("Response #{response.code} took #{((Time.now.to_f - start_time.to_f) * 1000).round} ms")

      return case response
      when Net::HTTPSuccess
        # Parse the requested JSON
        JSON.load(response.read_body)
      else
        # Essentially, rethrow the error
        response
      end
    end
  end


  # Fetch the coordinate (or coordinate*s*) matching this address.
  # This method includes error handling and retry logic.
  # It will return all matching addresses, in the form of a Hash object:
  # [{"formatted_address" => "what google thinks", "location" => {"lat" => float, "lng" => float}] 
  def encode(address)
    
    resultset = query_google(address)

    if resultset.nil?
      @log.fatal("Fatal error: nil response instead of an HTTP response of some kind from the attempt to query_google")
      return nil
    end

    until(resultset.kind_of?(Net::HTTPSuccess))
      @log.error("Error from Google API: #{resultset.code} #{resultset.message}: #{resultset.body.to_s}. Sleeping 5 seconds before the next retry")
      sleep(5)
      resultset = query_google(address)
  end


  # helper function to format the address the way Google wants it
  def self.encode_address(raw_address)
    raw_address.gsub(' ', '+')
  end
end

#@TEST: curl -i -k "https://maps.googleapis.com/maps/api/geocode/json?address=16215+NE+109th+St,+Redmond+WA+98052&key=AIzaSyBbQQxvFqayNuN_nE71m0Z7iUOSUigMZV4"

######################
######## MAIN ########
######################

if $0 == __FILE__

  # Configuration
  log = Logger.new('geocoding.log', 'daily')
  address_file = ARGV[-1]
  results_file = 'geocoded.csv'
  error_file   = 'geo_error.csv'
  g = Geocoder.new({:log => log})

  # Open the IO channels
  inf = File.open(address_file, 'r')
  outf = File.open(results_file, 'w')
  ef  = File.open(error_file, 'w')

  # Parse the input file, geocode the addresses, and save to a CSV file
  while(s=inf.gets)
    # Input file has one column: the address
    # It may have quotation marks around it from when it was encoded as CSV. Remove them if present
    addr = s.strip
    addr = addr[1...-1] if addr[0] == '"'
    geocode = g.encode(addr)

    # Google might return multiple results. Write an error to a separate file from successful searches
    if geocode.length > 1
      ef.puts JSON.generate({'address' => address, 'locations' => geocode})
      outf.puts "\"#{address}\",MULTIPLE,MULTIPLE,MULTIPLE" # Keep the output file with the same number and order of rows as the input file
    elsif geocode.length == 0
      outf.puts "\"#{address}\"" # Keep the output file with the same number and order of rows as the input file
    else
      outf.puts "\"#{address}\",#{geocode[0]['geometry']['lat']},#{geocode[0]['geometry']['lng']},\"#{geocode[0]['formatted_address']}\""
    end
  end


  inf.close
  outf.flush
  outf.close
  ef.flush
  ef.close

  
  puts g.encode(ARGV[-1])
end
