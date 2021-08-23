module Rom
  module Dynamo
    class Relation < ROM::Relation
      include Enumerable
      forward :restrict, :batch_restrict, :index_restrict
      forward :limit, :reversed, :offset
      adapter :dynamo

      def each_page(&block)
        dataset.each_page(&block)
      end
    end
  end
end
