require 'rom/commands'

module Rom
  module Dynamo
    module Commands
      # DynamoDB create command
      class Create < ROM::Commands::Create
        def execute(tuple)
          attributes = input[tuple]
          validator.call(attributes)
          relation.insert(attributes.to_h)
          []
        end
      end

      # DynamoDB delete command
      class Delete < ROM::Commands::Delete
        def execute
          target.to_a.tap do |tuples|
            tuples.each { |t| relation.delete(t) }
          end
        end
      end
    end
  end
end
