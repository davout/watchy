require 'watchy/config/field_config_builder'

require 'watchy/insert_rule'
require 'watchy/update_rule'

module Watchy
  module Config

    # 
    # Handles the tables related configuration hashes
    #
    class TableConfigBuilder

      def initialize
        @config = {
          rules: {
            insert: [],
            update: [],
            delete: []
          },
          fields: {},
          versioning_enabled: true
        }
      end

      #
      # Defines a field to audit
      #
      # @param block [Proc] The configuration block for this table
      #
      def field(name, &block)
        @config[:fields][name] = Docile.dsl_eval(Watchy::Config::FieldConfigBuilder.new, &block).build
      end

      #
      # Defines a rule that should be enforced each time a row is inserted
      #
      def on_insert(*args, &block)
        raise 'Block must accept a single argument' unless (block.arity == 1)
        @config[:rules][:insert] << Watchy::InsertRule.new(args.shift, &block)
      end

      #
      # Defines a rule that should be enforced each time a row is updated
      #
      def on_update(*args, &block)
        raise 'Block must accept a two arguments' unless (block.arity == 2)
        @config[:rules][:update] << Watchy::UpdateRule.new(args.shift, &block)
      end

      #
      # Defines a rule that should be enforced each time a row is deleted
      #
      def on_delete(*args, &block)
        raise 'Block must accept a single argument' unless (block.arity == 1)
        @config[:rules][:delete] << Watchy::DeleteRule.new(args.shift, &block)
      end

      #
      # Disables versioning for the table
      #
      def disable_versioning!
        @config[:versioning_enabled] = false
      end

      #
      # Builds the defined configuration as a hash
      #
      # @return [Hash] The configuration hash
      #
      def build
        @config
      end

    end
  end
end

