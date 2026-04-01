# frozen_string_literal: true

describe ROM::Dynamo::Gateway do

  let(:gateway) { described_class.new(uri) }
  let(:uri)     { LOCAL_DYNAMO_URI }

  describe ".new" do
    it "creates the gateway with uri" do
      c = described_class.new(LOCAL_DYNAMO_URI).ddb.config
      expect(c.endpoint).to eq(URI.parse('http://localhost:8000/'))
      expect(c.region).to eq('us-east-1')
    end
  end # describe .new

  describe "#options" do
    subject(:options) { gateway.options }

    it "returns a uri" do
      expect(options).to eql({
        endpoint: 'http://localhost:8000/',
        region: 'us-east-1'
      })
    end
  end # describe #options

  describe "#[]" do
    subject(:lookup) { gateway["items"] }

    context "by default" do
      it { is_expected.to be_nil }
    end

    context "registered dataset" do
      before { gateway.dataset "items" }
      it { is_expected.to be_instance_of ROM::Dynamo::Dataset }
    end
  end # describe #[]

  describe "#dataset?" do
    subject(:dataset_exists) { gateway.dataset? "items" }

    context "by default" do
      it { is_expected.to be false }
    end

    context "registered dataset" do
      before { gateway.dataset "items" }
      it { is_expected.to be true }
    end
  end # describe #dataset?

  describe "#dataset" do
    subject(:register_dataset) { gateway.dataset(name) }

    context "with valid name" do
      let(:name) { :items }

      it "registers the dataset for given table" do
        register_dataset
        dataset = gateway["items"]
        expect(dataset.name).to eq('test_app_items')
      end
    end

    context "with a string name" do
      let(:name) { "items" }

      it "registers the dataset for given table" do
        expect { register_dataset }.to(change { gateway[:items] })
      end
    end
  end # describe #dataset
end # describe ROM:Dynamo::Gateway
