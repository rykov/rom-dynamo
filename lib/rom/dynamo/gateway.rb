# frozen_string_literal: true

require 'addressable/uri'
require 'rom/gateway'

module Rom
  module Dynamo
    class Gateway < ROM::Gateway
      attr_reader :ddb, :options, :logger

      def initialize(uri)
        super()
        uri = Addressable::URI.parse(uri)
        opts = { region: uri.host }
        opts.merge!(uri.query_values) if uri.query
        opts.keys.each { |k| opts[k.to_sym] = opts.delete(k) }

        @options = opts
        @ddb = Aws::DynamoDB::Client.new(@options)
        @prefix = uri.path.gsub('/', '')
        @datasets = {}
      end

      def use_logger(logger)
        @logger = logger
      end

      def dataset(name)
        name = "#{@prefix}#{name}"
        @datasets[name] ||= _has?(name) && Dataset.new(connection: @ddb, name: name, logger: @logger)
      end

      def dataset?(name)
        !!self[name]
      end

      def [](name)
        @datasets["#{@prefix}#{name}"]
      end

    private
      def _has?(name)
        @ddb.describe_table(table_name: name)
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException
        return false
      end
    end
  end
end
