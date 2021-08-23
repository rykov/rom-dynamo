# encoding: utf-8

describe ROM::Dynamo do
  let(:uri) { LocalDynamoURI }
  let(:table_name) { "items" }
  let(:rom) { ROM.container(:dynamo, uri) { |config|

    config.relation(:items) do
      schema(infer: true)

      def by_id(id)
        restrict(id: id).with(auto_struct: false)
      end
    end

  } }

  class ItemsRepo < ROM::Repository[:items]
    commands :create, update: :by_id, delete: :by_id

    def by_id(id)
      items.restrict(id: id).one
    end

    def by_parent_index(p)
      items.index_restrict('parent-index', parent: p)
    end

    def multi_id(keys)
      items.batch_restrict(keys)
    end
  end

  describe '#create' do
    let(:items_repo) { ItemsRepo.new(rom) }

    it 'should create and retrieve item' do
      items_repo.create({ id: 1, name: 'Jeff' })
      item = items_repo.by_id(1)
      expect(item.id).to eq(1)
      expect(item.name).to eq('Jeff')
    end
  end

  describe '#query' do
    let(:items_repo) { ItemsRepo.new(rom) }

    before do
      items_repo.create({ id: 1, parent: 'a', name: 'Jeff' })
      items_repo.create({ id: 2, parent: 'a', name: 'Bob' })
      items_repo.create({ id: 3, parent: 'b', name: 'Jim' })
    end

    it 'should retrieve items by batch' do
      results = items_repo.multi_id([2,3]).to_a
      expect(results.map(&:id)).to match_array([2, 3])
    end

    it 'should retrieve items by index' do
      results = items_repo.by_parent_index('a').to_a
      expect(results.map(&:id)).to match_array([1, 2])
    end

    it 'should retrieve item with limit' do
      results = items_repo.by_parent_index('a').limit(1)
      expect(results.map(&:id)).to match_array([1])
    end

    it 'should retrieve item with offset' do
      offset = { parent: 'a', id: 1 }
      results = items_repo.by_parent_index('a').offset(offset)
      expect(results.map(&:id)).to match_array([2])
    end

    it 'should retrieve using pagination' do
      parent_query = items_repo.by_parent_index('a').limit(1)

      page = parent_query.each_page.next
      expect(page.items.map { |i| i['id'] }).to match_array([1])
      expect(offset = page.last_evaluated_key).to_not be_nil

      page = parent_query.offset(offset).each_page.next
      expect(page.items.map { |i| i['id'] }).to match_array([2])
      expect(offset = page.last_evaluated_key).to_not be_nil

      page = parent_query.offset(offset).each_page.next
      expect(page.items.map { |i| i['id'] }).to match_array([])
      expect(page.last_evaluated_key).to be_nil
    end
  end
end
