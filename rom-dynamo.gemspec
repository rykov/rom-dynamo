# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rom/dynamo/version'

Gem::Specification.new do |spec|
  spec.name          = "rom-dynamo"
  spec.version       = Rom::Dynamo::VERSION
  spec.authors       = ["Michael Rykov"]
  spec.email         = ["mrykov@gmail.com"]

  spec.summary       = 'DynamoDB adapter for Ruby Object Mapper'
  spec.description   = 'DynamoDB adapter for Ruby Object Mapper'
  spec.homepage      = "https://github.com/rykov/rom-dynamo"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Ruby 2.0 and above
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Runtime
  spec.add_dependency "addressable", "~> 2.3"
  spec.add_dependency "rom", ">= 1.0", "< 6.0"
  spec.add_dependency "aws-sdk-dynamodb", "~> 1.0"

  # Development
  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
