# encoding: utf-8
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'addressable/uri'

# Default Dynamo
ep = Addressable::URI.encode('http://localhost:8000/')
LocalDynamoURI = "dynamo://us-east-1/test_app_/?endpoint=#{ep}"

# Loads the code under test
require 'rom-dynamo'

# Configures RSpec
require 'config/reset_cluster'
require 'config/rom'
require 'config/test_module'
