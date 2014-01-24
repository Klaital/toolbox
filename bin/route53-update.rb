#!/usr/bin/env ruby
require 'aws-sdk'
require_relative '../lib/configs_aws'

def find_cname_for_domain(domain)
  r53 = AWS::Route53.new
  domain_rset = nil
  r53.hosted_zones.each do |hz|
    puts "[#{hz.id}]\t#{hz.name}: #{hz.resource_record_set_count}"
    hz.resource_record_sets.each do |rset|
      if (rset.name == domain)
        puts "[#{hz.id}]\tRSet\t'#{rset.name}'"
        puts "[#{hz.id}]\tRsetType\t#{rset.type}"
        puts "[#{hz.id}]\tRSetID\t#{rset.set_identifier}"
        puts "[#{hz.id}]\tRSetRR\t#{rset.resource_records}"
        puts "[#{hz.id}]\tValue\t#{rset.resource_records.to_s}"
        domain_rset = rset
      end
    end
  end

  domain_rset
end


def usage
  str = <<USAGE
route53-update: Inform Route53 of a change in this server's IP
Usage: ruby route53-update.rb <DOMAIN_NAME> [HOSTNAME_OVERRIDE]
Example: 
> ruby route53-update.rb 3pg-enlistener.tmus.info

The IP address is pulled from ipecho.net

If you wish to override this default name, specify it as the second command line parameter, like this:
> ruby route53-update.rb 3pg-enlistener.tmus.info ec2-107-20-108-70.compute-1.amazonaws.com
USAGE
end

if (ARGV.length == 0)
  puts usage
  exit 1
end

domain =  ARGV[0]
new_value = if(ARGV.length >= 2)
  ARGV[1]
else
  `curl ipecho.net/plain`.strip
end

# These records have a trailing '.' character for some reason.
domain += '.' unless (domain[-1] == '.')

puts "Searching for Record Sets with name matching '#{domain}'"
rset = find_cname_for_domain(domain)
puts "#{rset}"

if (!rset.nil? && rset.type == 'A')
  puts "Updating A record with new value: #{new_value}"
  rset.resource_recordsi[0][:value] = new_value
  rset.update
end

