# frozen_string_literal: true

module Rom
  module Dynamo
    class Dataset
      include Enumerable
      include Dry::Equalizer(:name, :connection)
      extend Dry::Initializer[undefined: false]
      EMPTY_QUERY = { key_conditions: {}.freeze }.freeze

      option :connection
      option :name, proc(&:to_s)
      option :logger, optional: true
      option :table_keys, optional: true, reader: false
      option :query, default: proc { EMPTY_QUERY }, reader: false
      alias ddb connection

      ######### ENUMERATE ###########

      def each(&block)
        return enum_for(:each) if block.nil?
        each_page { |p| p.items.each(&block) }
      end

      def each_page(&block)
        return enum_for(:each_page) if block.nil?
        result = start_query(consistent_read: true)
        result.each_page(&block)
      end

      ############# QUERY #############

      def restrict(query = nil)
        return self if query.nil?
        dup_with_query(self.class, query)
      end

      def batch_restrict(keys)
        dup_as(BatchGetDataset, keys: keys.map do |k|
          dump(table_keys.zip(k.is_a?(Array) ? k : [k]).to_h)
        end)
      end

      def index_restrict(index, query)
        dup_with_query(GlobalIndexDataset, query, index_name: index.to_s)
      end

      ############# PAGINATE #############

      def limit(limit)
        opts = limit.nil? ? {} : { limit: limit.to_i }
        dup_with_query(self.class, nil, opts)
      end

      def offset(key)
        opts = key.nil? ? {} : { exclusive_start_key: dump(key) }
        dup_with_query(self.class, nil, opts)
      end

      def reversed
        dup_with_query(self.class, nil, scan_index_forward: false)
      end

      ############# WRITE #############
      def insert(hash)
        opts = { table_name: name, item: dump(hash) }
        connection.put_item(opts).attributes
      end

      def delete(hash)
        hash = dump(hash)
        connection.delete_item({
          table_name: name,
          key: hash_to_key(hash),
          **expression(:condition_expression, hash),
        }).attributes
      end

      def update(keys, hash)
        updates = dump(hash).reject { |k, _| table_keys.include?(k) }
        connection.update_item({
          table_name: name, key: hash_to_key(dump(keys)),
          **expression(:update_expression, updates, ', ', 'SET '),
        }).attributes
      end

      ############# HELPERS #############
    private
      def batch_get_each_page(keys, &block)
        !keys.empty? && ddb.batch_get_item({
          request_items: { name => { keys: keys } },
        }).each_page do |page|
          block.call(page[:responses][name])
        end
      end

      def dup_with_query(klass, key_hash, opts = {})
        conditions = @query[:key_conditions].merge(dump(key_hash || {}))
        opts = @query.merge(opts).merge!(key_conditions: conditions.freeze)
        dup_as(klass, query: opts.freeze)
      end

      # Expression params with a "#name = :value" clause per attribute, e.g.
      # { condition_expression: "#n0 = :v0 AND #n1 = :v1", ... }
      def expression(param, hash, joiner = ' AND ', lead = '')
        return {} if hash.empty?
        names, values = {}, {}

        clauses = hash.each_with_index.map do |(k, v), i|
          names["#n#{i}"] = k
          values[":v#{i}"] = v
          "#n#{i} = :v#{i}"
        end

        {
          param => "#{lead}#{clauses.join(joiner)}",
          expression_attribute_names: names,
          expression_attribute_values: values,
        }
      end

      def hash_to_key(hash)
        table_keys.each_with_object({}) do |k, out|
          out[k] = hash[k] if hash.key?(k)
        end
      end

      def table_keys
        @table_keys ||= begin
          r = ddb.describe_table(table_name: name)
          r[:table][:key_schema].map(&:attribute_name)
        end
      end

      def start_query(opts = {})
        opts = @query.merge(table_name: name).merge!(opts)
        opts.merge!(expression(:key_condition_expression, opts.delete(:key_conditions)))
        logger&.debug("Querying DDB: #{opts.inspect}")
        ddb.query(opts)
      end

      def dup_as(klass, opts = {})
        table_keys # To populate keys once at top-level Dataset
        attrs = Dataset.dry_initializer.attributes(self)
        klass.new(**attrs, **opts)
      end

      # Stringifies keys and serializes values
      def dump(hash)
        hash.each_with_object({}) { |(k, v), out| out[k.to_s] = dump_value(v) }
      end

      def dump_value(v)
        return v.new_offset(0).iso8601(6) if v.is_a?(DateTime)
        v.is_a?(Time) ? v.getutc.iso8601(6) : v
      end
    end

    # Batch get using an array of key queries
    # [{ key => val }, { key => val }, ...]
    class BatchGetDataset < Dataset
      option :keys

      # Query for records
      def each_page(&block)
        return enum_for(:each_page) if block.nil?
        batch_get_each_page(@keys) do |items|
          klass = Aws::DynamoDB::Types::QueryOutput
          block.call(klass.new(items: items, count: items.size))
        end
      end
    end

    # Dataset queried via a Global Secondary Index
    # Paginate through keys from Global Index and
    # call BatchGetItem for keys from each page
    class GlobalIndexDataset < Dataset
      def each_page(&block)
        return enum_for(:each_page) if block.nil?
        if @query[:limit]
          block.call(populated_results(start_query))
        else
          start_query(limit: 100).each_page do |p|
            block.call(populated_results(p))
          end
        end
      end

      private def populated_results(result)
        klass = Aws::DynamoDB::Types::QueryOutput
        keys = result.items.map { |h| hash_to_key(h) }
        klass.new(result.to_hash.merge(items: [].tap do |out|
          batch_get_each_page(keys) { |i| out.concat(i) }
        end))
      end

    end
  end
end
