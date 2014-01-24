require 'yaml'

CREDS = YAML.load_file(File.join(File.expand_path(File.dirname(__FILE__)), '..', 'config', 'credentials.yaml'))

# Adding a nice compacting method to the Hash based on value
class Hash
    def compact!
        delete_if {|k,v| v.nil?}
    end
end
