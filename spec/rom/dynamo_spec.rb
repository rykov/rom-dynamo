# frozen_string_literal: true

describe ROM::Dynamo do
  let(:uri) { LOCAL_DYNAMO_URI }
  let(:items_repo) { ItemsRepo.new(rom) }
  let(:time) { Time.utc(2020, 1, 2, 3, 4, 5) }
  let(:iso_time) { '2020-01-02T03:04:05.000000Z' }
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
    it 'creates and retrieve item' do
      items_repo.create({ id: 1, name: 'Jeff' })
      item = items_repo.by_id(1)
      expect(item.id).to eq(1)
      expect(item.name).to eq('Jeff')
    end

    it 'serializes time values' do
      items_repo.create({ id: 4, seen_at: time, born_at: time.to_datetime })
      expect(items_repo.by_id(4)).to have_attributes(
        seen_at: iso_time, born_at: '2020-01-02T03:04:05.000000+00:00'
      )
    end

    it 'serializes local times as UTC without changing them' do
      local = Time.new(2020, 1, 2, 5, 4, 5, '+02:00')
      items_repo.create({ id: 4, seen_at: local })
      expect(items_repo.by_id(4).seen_at).to eq(iso_time)
      expect(local.utc_offset).to eq(7200)
    end
  end

  describe '#query' do
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

    it 'retrieves items by full index key' do
      results = items_repo.by_parent_index('a').restrict(id: 2).to_a
      expect(results.map(&:id)).to contain_exactly(2)
    end

    it 'overrides earlier restrictions on the same key' do
      results = items_repo.items.restrict(id: 1).restrict('id' => 3).to_a
      expect(results.map(&:id)).to contain_exactly(3)
    end

    it 'serializes time values in restrictions' do
      items_repo.create({ id: 5, parent: time })
      results = items_repo.by_parent_index(time).to_a
      expect(results.map(&:id)).to contain_exactly(5)
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

    it 'serializes time values in offsets' do
      items_repo.create({ id: 5, parent: time })
      items_repo.create({ id: 6, parent: time })
      results = items_repo.by_parent_index(time).offset({ parent: time, id: 5 })
      expect(results.map(&:id)).to contain_exactly(6)
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

  describe '#update' do
    before { items_repo.create({ id: 10, parent: 'u', name: 'Jeff' }) }

    it 'overwrites existing attributes and adds new ones' do
      items_repo.update(10, name: 'Geoff', age: 5)
      expect(items_repo.by_id(10)).to have_attributes(parent: 'u', name: 'Geoff', age: 5)
    end

    it 'accepts string keys' do
      items_repo.update(10, 'name' => 'Geoff')
      expect(items_repo.by_id(10).name).to eq('Geoff')
    end

    it 'ignores key attributes' do
      items_repo.update(10, id: 10, name: 'Geoff')
      expect(items_repo.by_id(10).name).to eq('Geoff')
    end

    it 'allows a payload of only key attributes' do
      expect { items_repo.update(10, id: 10) }.not_to raise_error
      expect(items_repo.by_id(10).name).to eq('Jeff')
    end

    it 'serializes time values' do
      items_repo.update(10, seen_at: time)
      expect(items_repo.by_id(10).seen_at).to eq(iso_time)
    end

    it 'does nothing for missing items' do
      items_repo.update(11, name: 'Nobody')
      expect(items_repo.by_id(11)).to be_nil
    end
  end

  describe '#delete' do
    before { items_repo.create({ id: 20, parent: 'd', name: 'Jeff' }) }

    it 'deletes the item' do
      items_repo.delete(20)
      expect(items_repo.by_id(20)).to be_nil
    end

    it 'leaves other items alone' do
      items_repo.create({ id: 21, parent: 'd', name: 'Bob' })
      items_repo.delete(20)
      expect(items_repo.by_id(21).name).to eq('Bob')
    end

    it 'does nothing for missing items' do
      expect { items_repo.delete(22) }.not_to raise_error
      expect(items_repo.by_id(20)).not_to be_nil
    end

    it 'serializes time values in the condition' do
      items_repo.update(20, seen_at: time)
      items_repo.items.dataset.delete({ id: 20, seen_at: time })
      expect(items_repo.by_id(20)).to be_nil
    end

    it 'refuses to delete an item that has changed' do
      stale = { id: 20, parent: 'd', name: 'Bob' }
      expect { items_repo.items.dataset.delete(stale) }.to raise_error(
        Aws::DynamoDB::Errors::ConditionalCheckFailedException
      )
      expect(items_repo.by_id(20)).not_to be_nil
    end
  end
end
