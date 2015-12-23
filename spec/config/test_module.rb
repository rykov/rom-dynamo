# encoding: utf-8

# Recreates ROM::Dynamo::Test before every spec
RSpec.configure do |config|
  config.before { module ROM::Dynamo::Test; end }
  config.after  { ROM::Dynamo.send :remove_const, :Test }
end
