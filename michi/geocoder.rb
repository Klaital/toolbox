# geocoder.rb
# A library to facilitate API calls to the Google Geocoding Web Service
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'logger'
require 'csv'

require_relative '../lib/credentials.rb'

class Geocoder
  def initialize(opts={})
    @api_key = opts[:api_key] || CREDENTIALS['google']['geocode_api']['key']
    @log = opts[:log] || Logger.new($stdout)
    @api_url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$ADDRESS&key=$API_KEY'
  end

  def filter_by_county(api_results, select_county = 'King County')
    @log.debug {"Filtering to county = '#{select_county}'. Starting with #{api_results.length} results."}

    api_results.select do |location|
      # Find the address_components subdoc that contains the county info

      county = location['address_components'].select {|addr| addr['types'].include?('administrative_area_level_2') }

      if county.length == 0
        @log.warn {"Found no counties at all in location #{location['formatted_address']}"}
        false
      elsif county[0]['short_name'] == select_county
        @log.debug {"Found #{select_county}. This location will be kept: #{location['formatted_address']}"}
        true
      else
        @log.warn {"County '#{county[0]['short_name']}' is not '#{select_county}'. Removing location: #{location['formatted_address']}"}
        false
      end
    end
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
      @log.info {"Looking up '#{address}' via '#{endpoint}'"}
      start_time = Time.now
      response = http.request(request)
      @log.info {"Response #{response.code} took #{((Time.now.to_f - start_time.to_f) * 1000).round} ms"}

      @log.debug {"Response was #{response.body.length} characters. Contents: #{response.body}"}

      return case response
      when Net::HTTPSuccess
        # Parse the requested JSON
        JSON.load(response.read_body)['results']
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

    until(resultset.kind_of?(Hash) || resultset.kind_of?(Array))
      @log.error {"Error from Google API: #{resultset.code} #{resultset.message}: #{resultset.body.to_s}. Sleeping 5 seconds before the next retry"}
      sleep(5)
      resultset = query_google(address)
    end

    return resultset
  end


  # helper function to format the address the way Google wants it
  def self.encode_address(raw_address)
    raw_address.gsub(' ', '+')
  end

  def parse_file(inpath, outpath, errpath, opts={})
    # Read the input spreadsheet here
    inf = File.open(inpath, 'r')
    # Write the output spreadsheet here 
    outf = File.open(outpath, 'w')
    # Write out a log of any addresses with multiple locations found here
    # (this file is a list of JSON documents, one per line)
    errf = File.open(errpath, 'w')

    while s=inf.gets

      # Echo empty lines back into the output file
      if s.strip.length == 0
        outf.puts ""
        puts ""
        next
      end

      # Parse the line into an array. The CSV library correctly drops the
      # trailing newline character, and handles cells which use quotation
      # marks to enclose text containing a comma.
      line = s.parse_csv

      # Reassign the array entries into named variables.
      row_id, raw_address, lat, lng = line

      # Some rows already have the lat/long coordinates. Just echo these back out
      # TODO: check the accuracy of these coordinates against Google's
      unless lat.nil? || lng.nil?
        outf.print s
        print s
        next
      end

      # For the rest of rows, make an API call to find the lat/long coordinates possibly associated with the address
      # (there will likely be multiple results for vaguely-written addresses, such as merely '123 Fake St')
      locations = encode(raw_address)

      # We know from out-of-band knowledge that all of these addresses are in King County, WA.
      locations = filter_by_county(locations, 'WA')

    end

    inf.close
    outf.flush
    outf.close
    errf.flush
    errf.close
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
    next if addr.length == 0 # Skip empty lines outright
    addr = addr[1...-1] if addr[0] == '"'
    geocode = g.encode(addr)

    # Google might return multiple results. Write an error to a separate file from successful searches
    if geocode.length > 1
      ef.puts JSON.generate({'address' => addr, 'locations' => geocode})
      outs = "\"#{addr}\",MULTIPLE,MULTIPLE,MULTIPLE" # Keep the output file with the same number and order of rows as the input file
      outf.puts outs
      puts outs
    elsif geocode.length == 0
      outs = "\"#{addr}\"" # Keep the output file with the same number and order of rows as the input file
      outf.puts outs
      puts outs
    else
      outs = "\"#{addr}\",#{geocode[0]['geometry']['location']['lat']},#{geocode[0]['geometry']['location']['lng']},\"#{geocode[0]['formatted_address']}\""
      outf.puts outs
      puts outs
    end
  end


  inf.close
  outf.flush
  outf.close
  ef.flush
  ef.close
end

