# encoding: utf-8

describe ROM::Dynamo::Dataset do
  let(:uri) { LocalDynamoURI }
  let(:ddb) { ROM::Dynamo::Gateway.new(uri).ddb }
  let(:table_name) { "items" }

  describe 'initializer' do
    it 'should instantiate a Dataset' do
      ds = ROM::Dynamo::Dataset.new(name: table_name, connection: ddb)
      expect(ds).to be_a(ROM::Dynamo::Dataset)
      expect(ds.name).to eq(table_name)
      expect(ds.ddb).to eq(ddb)
    end

    it 'should allow conditions a Dataset' do
      ds = ROM::Dynamo::Dataset.new(name: table_name, connection: ddb)
      expect(ds).to be_a(ROM::Dynamo::Dataset)
      expect(ds.name).to eq(table_name)
      expect(ds.ddb).to eq(ddb)
    end
  end
end
