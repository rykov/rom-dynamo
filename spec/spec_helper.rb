# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'addressable/uri'

# Default Dynamo
ep = Addressable::URI.encode('http://localhost:8000/')
LOCAL_DYNAMO_URI = "dynamo://us-east-1/test_app_/?endpoint=#{ep}"

# Loads the code under test
require 'rom-dynamo'

# Configures RSpec
require 'config/local_dynamodb'
require 'config/reset_cluster'
require 'config/rom'
require 'config/test_module'
