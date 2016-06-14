# find_unprintable_cell.rb
# Find unprintable characters inside a TSV file.

input_path = ARGV[-1]

f = File.open(input_path, 'r')
line_no = 0
while(s=f.gets) do
	line_no += 1
	tokens = s.strip.split("\t")
	column_no = 0
	tokens.each do |v|
		column_no += 1
		# Check if the cell value contains any characters NOT in the ranges:
		# A-Z
		# a-z
		# 0-9
		# _,-
		if v.length > 0 && v =~ /[^[:print:]]/
			puts "Line #{line_no}, Column #{column_no} looks odd: #{v} (#{v.inspect})"
		end
	end
end

f.close
