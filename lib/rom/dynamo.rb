require 'rom'
require 'date'
require 'aws-sdk-dynamodb'
require "rom/dynamo/version"
require 'rom/dynamo/relation'
require 'rom/dynamo/commands'
require 'rom/dynamo/repository'

# jRuby HACK: https://github.com/jruby/jruby/issues/3645#issuecomment-181660161
module Aws; const_set(:DynamoDB, Aws::DynamoDB) end

# Register adapter with ROM-rb
ROM.register_adapter(:dynamo, Rom::Dynamo)
