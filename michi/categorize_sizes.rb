# categorize_sizes.rb
# Extract information from text about the size and number of units in each row.
require 'logger'

class SizeCategorizer
	def initialize(opts={})
		@log = opts[:logger] || Logger.new('sizing.log', 'daily')
	end

	def parse_line(line, line_no)
    @log.debug("Initializing line data (#{line_no}): #{line}")
		line_data = {
			:sqft_list => [],
			:sqft_total => 0,
			:units => 0,
      :housing_alert => false
		}

		# Clean up the single-column data cell. It will have a trailing newline, and sometimes a pair of quotation marks enclosing the text
		# There should not ever be more than one column
		line = line.strip
		line = line[1...-1] if line[0] == '"' && line[-1] == '"'

		# To deal with people writing "5-unit" and the like, we shall endeavor to remove all punctuation. 
		# This also deals with people who put commas as digit groupers in large numbers.
		line = line.gsub(/[-_]/, ' ').squeeze(' ').downcase

    # Set up the housing alerts if certain keywords/phrases are found in the text
    case line
    when /floating home/i
      line_data[:housing_alert] = true
    when /townho(use|me)/i
      line_data[:housing_alert] = true
    when /single family/i
      line_data[:housing_alert] = true
    when /sfr/i
      line_data[:housing_alert] = true
    when /mobile home/i
      line_data[:housing_alert] = true
    when /proposed parcel size/i
      line_data[:housing_alert] = true
    end

		#sqft = line.scan( /(\d+) (sq(\.|uare)( f(t\.|feet))?)/ )
		matches = line.scan( /(\d[\d,\.]*) ([^ ]+)( [^ ]+)?( [^ ]+)?/ )
    @log.debug("#{line_no} has #{matches.length} matchsets: #{matches}")
    return line_data if matches.length == 0 # Don't bother to analyze lines that didn't match the regex at least once

		matches.each do |matchset|
			next if matchset.length == 0 # Error trapping

			matchset.compact! # Remove any nonmatched groups. This deals with numbers with less than three trailing words.

      # Parse the matchset: Parse the first token into a Numeric type, and normalize any other strings into one of a known set of keywords.
      qty = 0 # how many square feet, or number of units. 
      type = nil # Should be set to 'unit', 'sqft' based on certain keywords. If none are found (i.e., this value is left alone), the default is to skip the match.
      skip = false # Set to true if certain negative keywords are found in the matchset, such as "demolition" or "addition"

      # Ensure we only consider matches that lead with a 'pure' number. This was easier than fixing the main regex and screwing up the match groups. I don't wanna rewrite that now.
      unless matchset[0].strip =~ /^\d[\d,]*(\.\d+)?$/
        @log.warn("Skipping an invalid number: #{matchset[0]}")
        next 
      end

      # Skip matchsets that say "\d+ to increase unit"
      if matchset.join(' ') =~ /^\d+ to increase unit/
        @log.warn("Skipping a suspected permit number: #{matchset[0]}")
        next
      end

      matchset.each do |match|
        case match.strip
        when /\d[\d,\.]*/
          # Remove any digit separators, then parse correctly as either a Float or Int, based on whether there is a decimal point.
          # Note the trailing 'unless' statement: we don't care about any numbers except the first in the list
          @log.debug("[Line #{line_no}] Parsing '#{match}' as numeric")
          qty = match.include?('.') ? match.gsub(',', '').to_f : match.gsub(',', '').to_i unless qty > 0

          # these huge numbers are all project/permit numbers, not actual unit/sqft counts
          if qty > 3000000
            @log.warn("Deciding to skip qty value #{qty} because it is probably a permit or project ID")
            skip = true
          end
        # These are 'type' keywords
        when /^sq/
          @log.debug("Token #{match} found to be sqft")
          type = 'sqft'
        when /^units?/
          @log.debug("Token #{match} found to be units")
          type = 'unit'

        # These are 'skip' keywords
        when /demoli/
          @log.debug("Token #{match} found to be 'demolition'")
          skip = true
        when /additions?/
          @log.debug("Token #{match} found to be 'additions")
          skip = true
        end
      end


      if skip
        @log.debug("Skipping matchset: #{matchset}")
        return line_data
      end

			case type
				when 'unit'
					line_data[:units] += qty
				when 'sqft'
					line_data[:sqft_total] += qty
					line_data[:sqft_list].push(qty)
			end

		end
    return line_data
	end

	def parse_file(input_path, output_path)
		@in = File.open(input_path, 'r')
		@out = File.open(output_path, 'w')
		line_no = 0

		# Some R&D stats
		lines_with_sqft = 0

		line_data = {}

		while(line=@in.gets)
			# Keep track of the line number. This is mostly useful for debugging.
			line_no += 1

			# Save the raw text
			line_data[line_no] = {:raw_line => line}

			# For the first row, output headers instead
			if line.strip =~ /^Permit Description$/i
				@out.puts "Permit Description,Square Footages,Total Sq.Ft.,Total # of Units,Housing Alert?"
				next
			end


			# Parse the square footage and unit data out of the line
			line_data[line_no].merge!(parse_line(line, line_no))

			# Generate five  columns of output: 
			# The original text  --  The list of square footages -- The sum of the square footages -- The sum of Units -- Housing Alerts
      @out.puts( SizeCategorizer.format_line_data(line_data[line_no], {:logger => @log}) )


			
			# # First reformat the set of square footages into a semicolon-separated list. If none were found in this row, set this column to 'review'
			# sqft_list = (line_data[:sqft_list].length == 0) ? 'review' : line_data[:sqft_list].join(';')

			# # Set the sum columns to be empty if none were found in each type
			# total_sqft = line_data[:sqft_total] == 0 ? '' : line_data[:sqft_total]
			# units = line_data[:units] == 0 ? '' : line_data[:units]
			# @out.puts "\"#{line_data[:raw_line].strip}\",#{sqft_list},#{total_sqft},#{units}"
		end
	end

  def self.format_line_data(data, opts={})
    log = opts[:logger] || Logger.new($stderr)
    if data.nil?
      log.error("No data!")
      return ""
    end

    if !data.kind_of?(Hash)
      log.error("Invalid data: expected a hash")
      return ""
    end

    log.debug("Reformatting line data (#{data})")
    # First reformat the set of square footages into a semicolon-separated list. If none were found in this row, set this column to 'review'
    sqft_list = (data[:sqft_list].length == 0) ? 'review' : data[:sqft_list].join(';')

    # Set the sum columns to be empty if none were found in each type
    total_sqft = data[:sqft_total] == 0 ? '' : data[:sqft_total]
    units = data[:units] == 0 ? '' : data[:units]
    "#{data[:raw_line].strip},#{sqft_list},#{total_sqft},#{units},#{data[:housing_alert]}"
  end
end

if $0 == __FILE__

  input_path = ARGV[-1]
  output_path = 'sqftunits.csv'

  log = Logger.new('sizing.log', 'daily')
  log.level = Logger::DEBUG

  sizer = SizeCategorizer.new({:logger => log})
  results = sizer.parse_file(input_path, output_path)

end
