module Rom
  module Dynamo
    class Relation < ROM::Relation
      include Enumerable
      forward :restrict, :batch_restrict, :index_restrict
      forward :limit, :reversed, :offset
      adapter :dynamo

      def each_page(&block)
        return enum_for(:each_page) if block.nil?
        dataset.each_page do |page|
          items = page[:items].map { |t| output_schema[t] }
          items = mapper.(items).to_a if auto_map?
          hash = page.to_hash.merge(items: items)
          hash[:last_evaluated_key] ||= nil
          block.call(ROM::OpenStruct.new(hash))
        end
      end
    end
  end
end
