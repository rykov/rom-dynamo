#!/usr/bin/env rake
# frozen_string_literal: true

require "bundler/gem_tasks"
require 'rspec/core'
require 'rspec/core/rake_task'

task :default => :spec
RSpec::Core::RakeTask.new

desc "Install DynamoDB Local for testing"
task :install_dynamodb do
  sh "cd spec/java && mvn package -q"
end
