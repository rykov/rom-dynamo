# frozen_string_literal: true

describe ROM::Dynamo do
  let(:uri) { LOCAL_DYNAMO_URI }
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

    it 'creates and retrieve item' do
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

    it 'retrieves items by batch' do
      results = items_repo.multi_id([2, 3]).to_a
      expect(results.map(&:id)).to contain_exactly(2, 3)
    end

    it 'retrieves items by index' do
      results = items_repo.by_parent_index('a').to_a
      expect(results.map(&:id)).to contain_exactly(1, 2)
    end

    it 'retrieves item with limit' do
      results = items_repo.by_parent_index('a').limit(1)
      expect(results.map(&:id)).to contain_exactly(1)
    end

    it 'retrieves item with offset' do
      offset = { parent: 'a', id: 1 }
      results = items_repo.by_parent_index('a').offset(offset)
      expect(results.map(&:id)).to contain_exactly(2)
    end

    it 'retrieves using pagination' do
      parent_query = items_repo.by_parent_index('a').limit(1)

      page = parent_query.each_page.next
      expect(page.items.map(&:id)).to contain_exactly(1)
      expect(offset = page.last_evaluated_key).not_to be_nil

      page = parent_query.offset(offset).each_page.next
      expect(page.items.map(&:id)).to contain_exactly(2)
      expect(offset = page.last_evaluated_key).not_to be_nil

      page = parent_query.offset(offset).each_page.next
      expect(page.items.map(&:id)).to eq([])
      expect(page.last_evaluated_key).to be_nil
    end
  end
end
