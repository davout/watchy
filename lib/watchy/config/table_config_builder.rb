require 'watchy/config/field_config_builder'

module Watchy
  module Config

    # 
    # Handles the tables related configuration hashes
    #
    class TableConfigBuilder

      def initialize
        @config = {}
      end

      #
      # Defines a field to audit
      #
      # @param block [Proc] The configuration block for this table
      #
      def field(&block)
        @config[:field] << Docile.dsl_eval(Watchy::Config::FieldConfigBuilder.new, &block).build
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

