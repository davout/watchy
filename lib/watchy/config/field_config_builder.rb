module Watchy
  module Config

    #
    # Handles field related configuration hashes
    #
    class FieldConfigBuilder

      def initialize
        @config = {
          insert: [],
          update: []
        }
      end

      def on_update(*args, &block)
        raise 'Block must accept a two arguments' unless (block.arity == 2)
        @config[:update] << Watchy::UpdateRule.new(*args, &block)
      end

      def on_insert(*args, &block)
        raise 'Block must accept a single argument' unless (block.arity == 1)
        @config[:insert] << Watchy::InsertRule.new(*args, &block)
      end

      #
      # Builds the defined configuration as a hash
      #
      def build
        { rules: @config } 
      end

    end
  end
end
