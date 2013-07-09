require 'watchy/config/field_config_builder'

module Watchy
  module Config
    class TableConfigBuilder

      def initialize
        @config = {}
      end

      #
      # Defines a field to audit
      #
      def field(&block)
        @config[:field] << Docile.dsl_eval(Watchy::Config::FieldConfigBuilder.new, &block).build
      end

      def build
        @config
      end

    end
  end
end

