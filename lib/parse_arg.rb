def parse_arg(args, patterns, expect_value=false, default_value=nil)
  if (!patterns.kind_of?(Array))
    patterns = [patterns]
  end

  args.each_index do |i|
    patterns.each do |pattern|
      if (args[i] == pattern)
        if (expect_value)
          return args[i+1] if (args.length > i+1)
        else
          return true
        end
      end
    end     
  end
  
  return default_value
end

# Return an array containing all 'unaffiliated' arguments, 
# meaning they are not preceeded by a parameter starting with '-'
def parse_extra_args(args)
  # Special case: consider a single argument
  if (ARGV.length == 1)
    return (ARGV[0].start_with?('-')) ? [] : [ARGV[0]]
  end
  
  args[0..-2].each_index do |i|
    if (args[i].start_with?('-'))
      # Delete the flag, and its value if present
      args.delete_at(i+1) unless(args[i+1].nil? || args[i+1].start_with?('-'))
      args.delete_at(i)
    end
  end
  
  # Special case: consider the last argument
  if (ARGV[-2].start_with?('-') && !ARGV[-1].start_with?('-'))
    args.unshift(ARGV[-1])
  end
  return args
end
