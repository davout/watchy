require 'watchy/config/table_config_builder'
require 'watchy/default_delete_rule'

module Watchy
  module Config

    #
    # Handles building the configuration sub-hash describing what to audit
    #   and how to audit it
    #
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
          @config[:tables][name] = {
            rules: {
              insert: [],
              update: [],
              delete: [ Watchy::DefaultDeleteRule.new ]
            },
            versioning_enabled: true
          }
        end

        if @config[:tables][name][:rules][:delete].empty?
          @config[:tables][name][:rules][:delete] << Watchy::DefaultDeleteRule.new
        end
      end

      #
      # Builds the audit configuration as a hash
      #
      # @return [Hash] The configuration hash for the audit specifics
      #
      def build
        { audit: @config }
      end

    end
  end
end

