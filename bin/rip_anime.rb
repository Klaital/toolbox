# rip_anime.rb
# A wrapper for the Handbrake CLI tool for ripping Japanese language DVDs.
# I hope you share my preferences, because setting them was the purpose of the script.

require 'optparse'
require_relative File.join('..','lib','dvd_title.rb')

options = {
  'test_mode' => true, # By default, don't actually launch the ripping commands
  'src_path' => 'E:\\',
  'dst_root' => 'D:\\rips',
  'series_name' => '',
  'season'      => '1', # use TheTVDB.com notation: either a numeric season number, or 'Special' for OVAs and such
  'starting_ep_num' => 1,	
  'starting_title_num' => 1,
  'ep_count' => 1,
  'codec'       => 'x264',
  'quality'     => '20',
  'handbrake_cli' => 'C:\\Program Files\\Handbrake\\HandBrakeCLI.exe',
  'audio_languages' => ['Japanese', 'English'],
  'subtitle_languages' => ['English'],
  'test_scan_data' => nil,
}

OptionParser.new do |opts|
  opts.banner = "A handbrake cli wrapper specialized for anime ripping. Usage: #{__FILE__} [options]"

  opts.on('-r', '--run', '--rip', 'Actually run the rip commands after they\'ve been generated.') do
    options['test_mode'] = false
  end

  opts.on('-i', '--source PATH', 'The DVD root path') do |p|
    options['src_path'] = p
  end

  opts.on('-o', '--destination PATH', 'The directory to write the ripped files into') do |p|
    options['dst_root'] = p
  end

  opts.on('-n', '--name SERIES', 'The series title. Use one that will match in TheTVDB.com if you\'re using plex') do |t|
    options['series_name'] = t
  end

  opts.on('-s', '--season NUM', 'The season number. Just the numeric value, or "Special" in the case of movies/OVAs') do |i|
    options['season'] = i
  end

  opts.on('--start EP_NUM', 'The starting episode number for this disc') do |i|
    options['starting_ep_num'] = i.to_i
  end

  opts.on('--title TITLE_NUM', 'The title number (on the DVD) that corresponds with the first episode on the disc. This program assumes the rest of the episodes will be sequential after that.') do |i|
    options['starting_title_num'] = i.to_i
  end

  opts.on('-c', '--ep-count NUM', 'The total number of episodes found on this disc.') do |i|
    options['ep_count'] = i.to_i
  end

  opts.on('--test-scan-file PATH', 'Path to a file containing a pre-executed disc scan. Useful for testing only') do |p|
    options['test_scan_data'] = File.readlines(p)
  end


  opts.on_tail('-h', '--help', 'Display this help info') do 
    puts opts.to_s
    exit 1
  end

end.parse!

def generate_handbrake_rip_commands(options, dvd_titles)
  command_set = []

  # TODO: add support for pulling the episode title from TheTVDB.com at rip-time. This could be done during the disc scan, if I can get that working again.
  
  offset = 0
  options['ep_count'].times do |i|
    this_ep_num = options['starting_ep_num'] + offset
    this_title_num = options['starting_title_num'] + offset
    offset += 1

    command_set.push(dvd_titles[this_title_num].handbrake_rip_cmd(options.merge({'ep_num' => this_ep_num})))
  end

  return command_set
end

def scan_disk(options)
  # This is the test stub, used when I don't have a real disc on hand for dev work
  return options['test_scan_data'] unless options['test_scan_data'].nil?

  # Run the actual scan command
  scan_cmd = "#{options['handbrake_cli']} -i \"#{options['src_path']}\" -t 0 --scan"
  scan_results = `#{scan_cmd}`

  # Collect the results as an array of the lines
  scan_results.split("\n").collect{|t| t.strip}
end


##################
###### MAIN ######
##################

puts "> Got configuration:"
puts options.to_s

print "> Scanning disk..."
scan_lines = scan_disk(options)
if scan_lines.nil? || scan_lines.length == 0
  puts "\t[ERROR]"
  warn "No scan data found, aborting!"
  exit 1
else
  puts "\t[DONE]"
end

print "> Generating TitleSet from scan..."
titleset = DvdTitle.parse_handbrake_scan(scan_lines)
if titleset.nil?
  puts "\t[ERROR]"
  warn "Nil response to parsing, aborting."
  exit 1
else
  puts "\t[DONE] (#{titleset.keys.length})"
end



print "> Generating command set..."
command_set = generate_handbrake_rip_commands(options, titleset)
puts "\t[DONE] (#{command_set.length})"
command_set.each {|c| puts ">> `#{c}`"} 

unless options['test_mode']
  puts "> Starting ripping..."
  command_set.each_index do |i|
    puts ">> Starting rip ##{i+1} / #{command_set.length}. Rip logs going to 'rips.log'"
    puts ">> #{c}"
    rip_start = Time.now
    `#{c} > rips.log 2>&1`
    rip_duration = Time.now.to_i - rip_start.to_i
    puts ">> [DONE] (#{rip_duration} seconds)"
  end
end

