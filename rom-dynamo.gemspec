# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rom/dynamo/version'

Gem::Specification.new do |spec|
  spec.name          = "rom-dynamo"
  spec.version       = Rom::Dynamo::VERSION
  spec.authors       = ["Michael Rykov"]
  spec.email         = ["mrykov@gmail.com"]

  #if spec.respond_to?(:metadata)
  #  spec.metadata['allowed_push_host'] = "https://push.fury.io"
  #end

  spec.summary       = %q{DynamoDB adapter for Ruby Object Mapper}
  spec.description   = %q{DynamoDB adapter for Ruby Object Mapper}
  spec.homepage      = "https://github.com/rykov/rom-dynamo"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime
  spec.add_runtime_dependency "rom", "~> 0.5"
  spec.add_runtime_dependency "aws-sdk-core"

  # Development
  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
end
