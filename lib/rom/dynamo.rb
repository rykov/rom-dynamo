# frozen_string_literal: true

require 'rom'
require 'date'
require 'aws-sdk-dynamodb'
require 'rom/dynamo/version'
require 'rom/dynamo/dataset'
require 'rom/dynamo/relation'
require 'rom/dynamo/commands'
require 'rom/dynamo/gateway'

# jRuby HACK: https://github.com/jruby/jruby/issues/3645#issuecomment-181660161
Aws.const_set(:DynamoDB, Aws::DynamoDB) if RUBY_ENGINE == 'jruby'

# Register adapter with ROM-rb
ROM.register_adapter(:dynamo, Rom::Dynamo)
