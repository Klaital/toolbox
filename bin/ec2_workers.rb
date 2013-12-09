#!/usr/bin/env ruby
require_relative '../lib/configs_aws'
flooder_ami="ami-9ad349aa"
region="us-west-2"
flooder_count=4
instance_type = 't1.micro'
keypair_name = 'CloudMoogle'

def list_instances(ami, region, keys)
	instances = `ec2-describe-instances -O "#{keys[:access_key]}" -W "#{keys[:secret_key]}" --region #{region} -F "image-id=#{ami}" | grep INSTANCE | grep #{ami} | grep -v grep`.split("\n")

	instances.collect! do |line|
		if (line.strip.length == 0)
			nil
		else
			tokens = line.split("\t")
			{
				:instance_id => tokens[1],
				:ami         => tokens[2],
				:hostname    => tokens[3],
				:state       => tokens[5],
				:size        => tokens[8]
			}
		end
	end
	instances.compact
end

def run_instances(ami, region, count, instance_type, keys, user_data="auto-flooder|en_flooder")
	`ec2-run-instances #{ami} -O "#{keys[:access_key]}" -W "#{keys[:secret_key]}" -n #{count} -d "#{user_data}" --region #{region} --instance-type #{instance_type} -k CloudMoogle`.split("\n")
end
def usage
	"#{__FILE__} COMMAND\nCommands:\n\tlist: generate a list of running flooder instance ids\n\trun: launch a set of flooder instances\n"
end
def terminate(ami, region, keys)
	# If a string is given, consider it an AMI to kill all instances of. If it's an Array, consider it a list of instance IDs to kill.
	images = if (ami.kind_of?(Array))
		ami
	else
		list_instances(ami,region,keys).collect {|x| (x[:state] == 'running') ? x[:instance_id] : nil}
	end
	images.compact!
		
	images.collect {|name| `ec2-terminate-instances -O "#{keys[:access_key]}" -W "#{keys[:secret_key]}" --region #{region} #{name}`.strip}
end

def send_command(ami, region, keys, ssh_key, command_string)
	hosts = list_instances(ami, region, keys)
	puts hosts.join("\n")
	output = hosts.collect do |host| 
		next if (host[:state] != 'running')
		next if (host[:hostname].length == 0)
		cmd = "ssh -i #{ssh_key} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ec2-user@#{host[:hostname]} \"#{command_string}\""
		puts cmd if (defined?(DEBUG))
		fork {`#{cmd}`}
	end
	Process.waitall
end

##############
#### MAIN ####
##############
case(ARGV[0])
when 'list'
	if (ARGV.include?('-v'))
		puts list_instances(flooder_ami, region, KEYS)
	else
		list_instances(flooder_ami, region, KEYS).each do |instance|
			puts instance[:instance_id]
		end
	end
	
when 'run'
	count = (ARGV[-1] =~ /^\d+$/) ? ARGV[-1].to_i : flooder_count
	puts run_instances(flooder_ami, region, count, instance_type, KEYS).join("\n")
when 'kill'
	puts terminate(flooder_ami, region, KEYS).join("\n")
when 'send'
	puts send_command(flooder_ami, region, KEYS, "~/.ssh/#{keypair_name}.pem", ARGV[-1])
else
	puts usage
end

