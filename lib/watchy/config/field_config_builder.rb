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

      #
      # Adds an UPDATE check for this field
      #
      # @param rule_name [String] The rule identifier
      # @param block [Proc] The rule to execute, it should accept the watched row
      #   and the audit row as block params
      #
      # @return [String] A string is returned if the rule fails, it should contain the error description
      #
      def on_update(rule_name = nil, &block)
        raise 'Block must accept a two arguments' unless (block.arity == 2)
        @config[:update] << Watchy::UpdateRule.new(rule_name, &block)
      end

      #
      # Adds an INSERT check for this field
      #
      # @param rule_name [String] The rule identifier
      # @param block [Proc] The rule to execute, it should accept the inserted row as block param
      #
      # @return [String] A string is returned if the rule fails, it should contain the error description
      #
      def on_insert(rule_name = nil, &block)
        raise 'Block must accept a single argument' unless (block.arity == 1)
        @config[:insert] << Watchy::InsertRule.new(rule_name, &block)
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
