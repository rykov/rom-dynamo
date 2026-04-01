# frozen_string_literal: true

describe ROM::Dynamo::Dataset do
  let(:uri) { LOCAL_DYNAMO_URI }
  let(:ddb) { ROM::Dynamo::Gateway.new(uri).ddb }
  let(:table_name) { "items" }

  describe 'initializer' do
    it 'instantiates a Dataset' do
      ds = described_class.new(name: table_name, connection: ddb)
      expect(ds).to be_a(described_class)
      expect(ds.name).to eq(table_name)
      expect(ds.ddb).to eq(ddb)
    end

    it 'allows conditions on a Dataset' do
      ds = described_class.new(name: table_name, connection: ddb, conditions: { id: 1 })
      expect(ds).to be_a(described_class)
      expect(ds.name).to eq(table_name)
      expect(ds.ddb).to eq(ddb)
    end
  end
end
