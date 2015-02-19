require 'uri'
require 'rom/repository'

module Rom
  module Dynamo
    class Repository < ROM::Repository
      def initialize(uri)
        uri = URI.parse(uri)
        @connection = Aws::DynamoDB::Client.new(region: uri.host)
        @prefix = uri.path.gsub('/', '')
        @datasets = {}
      end

      def use_logger(logger)
        @logger = logger
      end

      def dataset(name)
        name = "#{@prefix}#{name}"
        @datasets[name] ||= Dataset.new(name, @connection)
      end

      def dataset?(name)
        name = "#{@prefix}#{name}"
        list = connection.list_tables
        list[:table_names].include?(name)
      end

      def [](name)
        @datasets[name]
      end
    end
  end
end
