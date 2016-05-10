# dvd_title.rb
# A Class to encapsulate data describing a Title from a DVD, as well as logic 
# pertinent to selecting audio and subtitle tracks and formatting ripping 
# commands.
# 

class DvdTitle
  attr_accessor :title, :audio_tracks, :subtitle_tracks
  attr_accessor :duration # kept as a string in original HH:MM:SS format

  def initialize
    @audio_tracks = {}
    @subtitle_tracks = {}
  end

  # Parse the @duration string into an integer number of seconds
  def duration_seconds
    return 0 if @duration.nil? 
    tokens = @duration.split(':')
    
    # Initialize with the least significant digits
    seconds = tokens[-1].to_i
    
    # Add the minutes digit, if present
    if tokens.length > 1
      seconds = seconds + (tokens[-2].to_i * 60)
    end

    # Add the hours digit, if present
    if tokens.length > 2
      seconds = seconds + (tokens[-3].to_i * 60 * 60)
    end

    return seconds
  end

  def to_s
    {
      "title" => @title,
      "duration" => @duration,
      "duration_seconds" => duration_seconds,
      "audio_tracks" => @audio_tracks,
      "subtitle_tracks" => @subtitle_tracks
    }.to_s
  end

  def self.parse_handbrake_scan(scan_lines=[])
    titles = {}

    current_title = nil
    current_track_type = '' # Whether a track language line is describing subtitles or audio

    scan_lines.each do |line|
      next unless line.strip[0] == '+'

      case line
      
      # If we encounter a line like this:
      # + title 1:
      # It indicates the start of a new title's block. We should save the 
      # previous work-in-progress to the titleset, then reuse the in-progress
      # pointer to start a new Title object.
      when /\+ title \d+:/
        # Save
        titles[current_title.title] = current_title unless current_title.nil?
        # reinitialize state variables
        current_title = DvdTitle.new
        current_track_type = nil 

        # Start parsing the new title's data
        current_title.title = line.gsub(/[^0-9]/, '').to_i

      # The duration is a string of HH:MM:SS
      # A method on the generated object will convert this to seconds on demand.
      when /  \+ duration: \d\d:\d\d:\d\d/
        current_title.duration = line[14..-1].strip

      # The actual audio and subtitle language track lines are formatted the 
      # same as far as this codebase is concerned.
      # Thus we just keep track of which kind are currently being parsed, 
      # rather than guessing based on the data in a single language's line.
      when /  \+ (audio|subtitle) tracks:/
        current_track_type = line.split(' ')[1]
      
      # When parsing a language track, we must reference current_track_type to 
      # know whether it is an audio vs. subtitle track.
      when /    \+ \d+, (English|Japanese)/
        tokens = line.split(' ')
        track_id = tokens[1].gsub(/[^0-9]/, '').to_i
        track_language = tokens[2]

        if current_track_type == 'audio'
          # group by language name
          current_title.audio_tracks[track_language] = [] unless current_title.audio_tracks.has_key?(track_language)
          current_title.audio_tracks[track_language].push(track_id)
        elsif current_track_type == 'subtitle'
          # group by language name
          current_title.subtitle_tracks[track_language] = [] unless current_title.subtitle_tracks.has_key?(track_language)
          current_title.subtitle_tracks[track_language].push(track_id)
        else
          warn "Unknown track type: #{current_track_type}. Unable to sort track line #{line}"
        end

      end
    end

    return titles
  end
end

##################
###### MAIN ######
##################

if __FILE__ == $0
  sample_scan_file = File.join(__dir__, '..', 'data', 'deon_scan.log')
  puts "> Reading sample file (#{sample_scan_file})..."
  lines = File.readlines(sample_scan_file)
  puts ">> Got #{lines.length} lines of scan data"

  puts "> Beginning parse..."
  titles = DvdTitle.parse_handbrake_scan(lines)
  puts ">> Parsed #{titles.length} titles from the scan text."

  titles.each_value {|t| puts t.to_s}
end
