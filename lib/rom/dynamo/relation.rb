module Rom
  module Dynamo
    class Relation < ROM::Relation
      include Enumerable
      forward :restrict, :batch_restrict, :index_restrict
      adapter :dynamo
    end

    class Dataset
      include Enumerable
      include Dry::Equalizer(:name, :connection)
      extend Dry::Initializer[undefined: false]
      
      option :connection
      option :name, proc(&:to_s)
      option :table_keys, optional: true, reader: false
      option :conditions, default: proc { {} }, reader: false
      alias_method :ddb, :connection

      ############# READ #############

      def each(&block)
        block.nil? ? to_enum : each_item({
          key_conditions: @conditions,
          consistent_read: true,
        }, &block)
      end

      def restrict(query = nil)
        return self if query.nil?
        dup_as(Dataset, conditions: merged_conditions(query))
      end

      def batch_restrict(keys)
        dup_as(BatchGetDataset, keys: keys.map do |k|
          Hash[table_keys.zip(k.is_a?(Array) ? k : [k])]
        end)
      end

      def index_restrict(index, query)
        dup_as(GlobalIndexDataset, index: index, conditions: merged_conditions(query))
      end

      ############# WRITE #############
      def insert(hash)
        opts = { table_name: name, item: stringify_keys(hash) }
        connection.put_item(opts).attributes
      end

      def delete(hash)
        hash = stringify_keys(hash)
        connection.delete_item({
          table_name: name,
          key: hash_to_key(hash),
          expected: to_expected(hash),
        }).attributes
      end

      def update(keys, hash)
        connection.update_item({
          table_name: name, key: hash_to_key(stringify_keys(keys)),
          attribute_updates: hash.each_with_object({}) do |(k, v), out|
            out[k] = { value: dump_value(v), action: 'PUT' } if !keys[k]
          end
        }).attributes
      end

      ############# HELPERS #############
    private
      def each_item(options, &block)
        opts = options.merge(table_name: name)
        puts "Querying DDB: #{opts.inspect}"
        connection.query(opts).each_page do |page|
          page[:items].each(&block)
        end
      end

      def batch_get_each_item(keys, &block)
        !keys.empty? && ddb.batch_get_item({
          request_items: { name => { keys: keys } },
        }).each_page do |page|
          out = page[:responses][name]
          out.each(&block)
        end
      end

      def merged_conditions(query)
        @conditions.merge(query_to_conditions(query))
      end

      def query_to_conditions(query)
        Hash[query.map do |key, value|
          [key, {
            attribute_value_list: [value],
            comparison_operator:  "EQ"
          }]
        end]
      end

      def to_expected(hash)
        hash && Hash[hash.map do |k, v|
          [k, { value: v }]
        end]
      end

      def hash_to_key(hash)
        table_keys.each_with_object({}) do |k, out|
          out[k] = hash[k] if hash.has_key?(k)
        end
      end

      def table_keys
        @table_keys ||= begin
          r = ddb.describe_table(table_name: name)
          r[:table][:key_schema].map(&:attribute_name)
        end
      end

      def dup_as(klass, opts = {})
        table_keys # To populate keys once at top-level Dataset
        attrs = Dataset.dry_initializer.attributes(self)
        klass.new(attrs.merge(opts))
      end

      # String modifiers
      def stringify_keys(hash)
        hash.each_with_object({}) { |(k, v), out| out[k.to_s] = v }
      end

      def dump_value(v)
        return v.new_offset(0).iso8601(6) if v.is_a?(DateTime)
        v.is_a?(Time) ? v.utc.iso8601(6) : v
      end
    end

    # Batch get using an array of key queries
    # [{ key => val }, { key => val }, ...]
    class BatchGetDataset < Dataset
      option :keys

      # Query for records
      def each(&block)
        batch_get_each_item(@keys, &block)
      end
    end

    # Dataset queried via a Global Index
    class GlobalIndexDataset < Dataset
      option :index

      # Paginate through key hashes from Global Index
      # And call BatchGetItem for keys from each page
      def each(&block)
        index_query.each_page do |page|
          @keys = page[:items].map { |h| hash_to_key(h) }
          batch_get_each_item(@keys, &block)
        end
      end

      private def index_query
        opts = { key_conditions: @conditions, limit: 100 }
        opts.merge!(table_name: name, index_name: @index)
        puts "Querying DDB: #{opts.inspect}"
        connection.query(opts)
      end
    end
  end
end
