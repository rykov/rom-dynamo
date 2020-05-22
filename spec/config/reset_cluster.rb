# encoding: utf-8

RSpec.configure do |config|

  # Prepares table auth.users using official Datastax ruby driver for Cassandra
  #
  # Populates table records [{id: 1, name: "joe"}, {id: 2, name: "jane"}]
  #
  def reset_cluster
    gwy = Rom::Dynamo::Gateway.new(LocalDynamoURI)
    ddb, opts = gwy.ddb, { table_name: "test_app_foo_bar" }
    ddb.delete_table(opts) if gwy.dataset('foo_bar')
    ddb.create_table(opts.merge(
      attribute_definitions: [
        { attribute_name: "id", attribute_type: "N" },
      ],
      key_schema: [
        { attribute_name: "id", key_type: "HASH" }
      ],
      provisioned_throughput: {
        read_capacity_units: 1,
        write_capacity_units: 1,
      },
    ))
  end

  # Prepares the cluster before the suit
  reset_cluster

  # Recreates cluster after every example, marked by :reset_cluster tag
  config.after(:example, :reset_cluster) { reset_cluster }
end # RSpec.configure
