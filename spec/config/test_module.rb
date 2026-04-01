# frozen_string_literal: true

# Recreates ROM::Dynamo::Test before every spec
RSpec.configure do |config|
  config.before { stub_const("ROM::Dynamo::Test", Module.new) }
end
