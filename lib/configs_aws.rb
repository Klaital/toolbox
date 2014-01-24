# Configure the AWS settings
require 'aws-sdk'
require_relative '../lib/configs'

AWS.config( {:access_key_id => CREDS[:aws][:access_key], :secret_access_key => CREDS[:aws][:secret_key]} )

