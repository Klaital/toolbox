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
