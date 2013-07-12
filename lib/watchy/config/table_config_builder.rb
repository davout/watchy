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
            update: []
          }
        }
      end

      #
      # Defines a field to audit
      #
      # @param block [Proc] The configuration block for this table
      #
      def field(name, &block)
        @config[:fields] ||= {}
        @config[:fields][name] = Docile.dsl_eval(Watchy::Config::FieldConfigBuilder.new, &block).build
      end

      #
      # Defines a rule that should be enforced each time a row is inserted
      #
      def check_on_insert(*args, &block)
        if block.nil?
          block = args.shift.to_proc
        end

        raise 'Block must accept a single argument' unless (block.arity == 1)
        define_rule(:insert, *args, &block)
      end

      #
      # Defines a rule that should be enforced each time a row is updated
      #
      def check_on_update(*args, &block)
        if block.nil?
          block = args.shift.to_proc
        end

        raise 'Block must accept a two arguments' unless (block.arity == 2)
        define_rule(:update, *args, &block)
      end

      #
      # Adds a rule to the config hash
      #
      def define_rule(*args, &block)
        event = args.shift
        if event == :insert
          @config[:rules][:insert] << Watchy::InsertRule.new(args.shift, &block)
        elsif event == :update
          @config[:rules][:update] << Watchy::UpdateRule.new(args.shift, &block)
        end
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

