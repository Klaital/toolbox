require_relative File.join('..','lib','configs')
require_relative File.join('..','lib','parse_arg')
require 'mongo'

def usage
  s = <<USAGE
ruby #{__FILE__} --database DB_NAME --collection COLLECTION_NAME [--input PATH] [--separator SEP] [--truncate]

A tool to load a text file into a MongoDB collection, using the first row to define the field names.

 --database, -db DB_NAME          -- Specify the database name. Required. 
                                     Will be created if not extant.
 --collection, -c COLLECTION_NAME -- Specify the collection name. Required.
                                     Will be created if not extant.
 --input, -i PATH    -- Specify the name of the file to be loaded. If none 
                        is given, data will be read from standard input on 
                        the console.
 --separator, -s SEP -- Specify the delimitor character. Defaults to TAB.
 --truncate          -- If specified, drop all existing data from the
                        collection before importing.
USAGE

end

database = parse_arg(ARGV, ['--database','-db'], true)
collection = parse_arg(ARGV, ['--collection', '-c'], true)
input_path = parse_arg(ARGV, ['--input','-i'], true)
do_truncate = parse_arg(ARGV, ['--truncate'], false)
delimitor = parse_arg(ARGV, ['--separator','-s', '-d', '--delimitor'], true, "\t")

if database.nil? || collection.nil?
  puts usage
  exit 1
end

input_stream = if input_path.nil?
  $stdin
elsif File.exist?(input_path)
  File.open(input_path, 'r')
else
  puts "Unable to open input file: #{input_path}"
  exit 1
end

db = Mongo::MongoClient.new.db(database)
coll = db[collection]

if do_truncate
  puts "Dropping documents from collection #{database}.#{collection}"
  coll.remove
end

# Read the input file and load up the database
headers = input_stream.gets
if headers.nil?
  puts "No header row found."
  exit 1
end
headers = headers.split(delimitor).collect {|t| t.strip}

input_stream.each_line do |line|
  # Skip empty lines
  next if line.nil? || line.strip.length == 0
  
  # Tokenize the string and validate length
  tokens = line.strip.split(delimitor)
  if tokens.length > headers.length
    puts "Invalid line: #{tokens.length} tokens found, #{headers.length} tokens expected."
    next
  end
  
  doc = Hash.new
  headers.each_index do |i|
    # Add the datum to the document, skipping nodes where the value is empty.
    doc[headers[i]] = tokens[i].strip unless tokens[i].strip.length == 0
  end
  id = coll.insert(doc)
  puts "#{id} => \t#{doc.to_s}"
end

