require 'rom/commands'

module Rom
  module Dynamo
    module Commands
      # DynamoDB create command
      class Create < ROM::Commands::Create
        def execute(tuple)
          attributes = input[tuple]
          dataset.insert(attributes.to_h)
          []
        end

        def dataset
          relation.dataset
        end
      end

      # DynamoDB update command
      class Update < ROM::Commands::Update
        def execute(params)
          attributes = input[params]
          relation.map do |tuple|
            dataset.update(tuple, attributes.to_h)
          end
        end

        def dataset
          relation.dataset
        end
      end

      # DynamoDB delete command
      class Delete < ROM::Commands::Delete
        def execute
          relation.to_a.tap do |tuples|
            tuples.each { |t| dataset.delete(t) }
          end
        end

        def dataset
          relation.dataset
        end
      end
    end
  end
end
