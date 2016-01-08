module Rom
  module Dynamo
    class Relation < ROM::Relation
      include Enumerable
      forward :restrict, :index_restrict
      adapter :dynamo
    end

    class Dataset
      include Enumerable
      include Dry::Equalizer(:name, :connection)
      attr_reader :name, :connection
      alias_method :ddb, :connection

      def initialize(name, ddb, conditions = nil)
        @name, @connection = name, ddb
        @conditions = conditions || {}
      end

      ############# READ #############

      def each(&block)
        block.nil? ? to_enum : each_item({
          key_conditions: @conditions,
          consistent_read: true,
        }, &block)
      end

      def restrict(query = nil)
        return self if query.nil?
        conds = query_to_conditions(query)
        conds = @conditions.merge(conds)
        dup_as(Dataset, conditions: conds)
      end

      def index_restrict(index, query)
        conds = query_to_conditions(query)
        conds = @conditions.merge(conds)
        dup_as(GlobalIndexDataset, index: index, conditions: conds)
      end

      ############# WRITE #############
      def insert(hash)
        opts = { table_name: name, item: stringify_keys(hash) }
        connection.put_item(opts)
      end

      def delete(hash)
        hash = stringify_keys(hash)
        connection.delete_item({
          table_name: name,
          key: hash_to_key(hash),
          expected: to_expected(hash),
        })
      end

      def update(keys, hash)
        connection.update_item({
          table_name: name, key: hash_to_key(stringify_keys(keys)),
          attribute_updates: hash.each_with_object({}) do |(k, v), out|
            out[k] = { value: dump_value(v), action: 'PUT' } if !keys[k]
          end
        })
      end

      ############# HELPERS #############
    private
      def each_item(options, &block)
        puts "Querying #{name} ...\nWith: #{options.inspect}"
        connection.query(options.merge({
          table_name: name
        })).each_page do |page|
          page[:items].each(&block)
        end
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
        vars = [:@name, :@connection, :@conditions, :@table_keys]
        klass.allocate.tap do |out|
          vars.each { |k| out.instance_variable_set(k, instance_variable_get(k)) }
          opts.each { |k, v| out.instance_variable_set("@#{k}", v) }
        end
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

    # Dataset queried via a Global Index
    class GlobalIndexDataset < Dataset
      attr_accessor :index

      def each(&block)
        # Pull record IDs from Global Index
        keys = []; each_item({
          key_conditions: @conditions,
          index_name: @index
        }) { |hash| keys << hash_to_key(hash) }

        # Bail if we have nothing
        return if keys.empty?

        # Query for the actual records
        ddb.batch_get_item({
          request_items: { name => { keys: keys } },
        }).each_page do |page|
          out = page[:responses][name]
          out.each(&block)
        end
      end

    end
  end
end
