# load_mongo_from_tsv.rb
#
# @author Chris Cox
# @date 2014-01-29
#
# A simple tool for pushing data from a flatfile into a MongoDB database 
# 

require_relative File.join('..','lib','configs')
require_relative File.join('..','lib','parse_arg')
require 'mongo'
require 'optparse'

database = 'test'
collection = 'auto_import' 
input = $stdin
do_truncate = false
delimitor = '\t'
chomp_str = nil

OptionParser.new do |opt|
  opt.banner = <<USAGE
ruby #{__FILE__} --database DB_NAME --collection COLLECTION_NAME [--input PATH] [--separator SEP] [--truncate]

A tool to load a text file into a MongoDB collection, using the first row to define the field names.
USAGE
  opt.on('-db', '--database DB', 'Specify the database name. Required. Will be created if not extant.') do |db|
    database = db
  end

  opt.on('-c', '--collection COLL', 'Sepcify the collection name. Required. Will be created if not extant.') do |coll|
    collection = coll
  end
  
  opt.on('-i', '--input PATH', 'Specify the name of the file to be loaded. If none is given, data will be read from standard input on the console.') do |path|
    input = File.open(path, 'r')
  end

  opt.on('-s', '--separator CHAR', 'Specify the delimitor character. Defaults to TAB.') do |sep|
    delimitor = sep
  end

  opt.on('-t', '--truncate', 'Drop all existing data from the collection before importing.') do
    do_truncate = true
  end

  opt.on('--chomp CHAR', 'Characters to remove if found at both the beginning and end of a token') do |char|
    chomp_str = char
  end

  opt.on_tail('-h', '--help', 'Display this messgae') do
    puts opt
    exit(0)
  end

end.parse!

db = Mongo::MongoClient.new.db(database)
coll = db[collection]

if do_truncate
  puts "Dropping documents from collection #{database}.#{collection}"
  coll.remove
end

# Read the input file and load up the database
headers = input.gets
if headers.nil?
  puts "No header row found."
  exit 1
end
headers = headers.split(delimitor).collect do |t| 
  t.strip
end

input.each_line do |line|
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

