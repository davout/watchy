require 'watchy/config/table_config_builder'

module Watchy
  module Config
    class AuditConfigBuilder

      def initialize
        @config = {
          tables: {}
        }
      end

      #
      # Defines a table to audit
      #
      def table(name, &block)
        if block
          @config[:tables][name] = Docile.dsl_eval(Watchy::Config::TableConfigBuilder.new, &block).build
        else
          @config[:tables][name] = {}
        end
      end

      def build
        { audit: @config }
      end

    end
  end
end

