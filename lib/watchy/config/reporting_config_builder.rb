require 'watchy/reports/violations'
require 'watchy/reports/activity'

module Watchy
  module Config

    # 
    # Handles the reporting related configuration hash
    #
    class ReportingConfigBuilder

      def initialize
        @reports = [ 
          Watchy::Reports::Violations.new,
          Watchy::Reports::Activity.new
        ]
      end

      #
      # Adds a report to the report collection, and sets the run interval
      #   according to the +cron_def+ parameter.
      #
      # @param report_class [Watchy::Report] The report class, which should subclass +Watchy::Report+
      # @param cron_def [String] The cron definition, if +nil+ is given the report
      #   will never be run
      #
      def report(report_class, cron_def = nil)
        @reports << report_class.new(cron_def)
      end

      #
      # Builds the defined configuration as a hash
      #
      # @return [Hash] The configuration hash
      #
      def build
        { reports: @reports }
      end

    end
  end
end

