require 'watchy/report'
require 'watchy/tables_helper'

module Watchy

  module Reports

    #
    # This report shows statistics on activity that happened
    #   recently such as insertions, deletions, updates
    #
    class Activity < Watchy::Report

      include Watchy::TablesHelper

      # The default interval betwee activity reports
      HOURS = 6

      def initialize(crondef = nil)
        super(crondef || "0 */#{HOURS} * * *")
      end

      #
      # The report template contents as a string
      #
      # @return [String] The temaplate contents
      #
      def template
        File.read(File.expand_path('../../../../templates/activity.md.mustache', __FILE__))
      end

      #
      # The generation time
      #
      # @return [Time] The current time
      #
      def generated_at
        Time.now
      end

      #
      # The activity that happened during the last +HOURS+
      #
      # @return [Hash] The activity as a hash
      #
      def activity
        act = []

        tables.each do |table|
          act << {
            table: table.name,
            stats: [
              {
                action: 'INSERTs',
                value: db.query("SELECT COUNT(*) AS CNT FROM #{table.audit} WHERE `_copied_at` >= #{cutoff.to_i}").to_a[0]['CNT']
              },
              {
                action: 'DELETEs',
                value: db.query("SELECT COUNT(*) AS CNT FROM #{table.audit} WHERE `_deleted_at` >= #{cutoff.to_i}").to_a[0]['CNT']
              },
              {
                action: 'UPDATEs',
                value: db.query("SELECT COUNT(*) AS CNT FROM #{table.audit} WHERE `_copied_at` < #{cutoff.to_i} AND _last_version >= #{cutoff.to_i}").to_a[0]['CNT']
              },
              {
                action: 'Violations',
                value: db.query("SELECT COUNT(*) AS CNT FROM `#{audit_db}`._rule_violations WHERE `audited_table` = '#{table.name}' AND `stamp` > #{cutoff.to_i}").to_a[0]['CNT']
              }
            ]
          }
        end

        act
      end

      #
      # The cutoff timestamp for retrieving the activity data
      #
      # @return [Time] The time it was +HOURS+ ago
      #
      def cutoff
        Time.now - (60 * 60 * HOURS)
      end

      #
      # The cutoff time as string
      #
      # @return [String] The cutoff time
      #
      def cutoff_str
        cutoff.strftime('%Y-%m-%d %H:%M:%S')
      end

      #
      # Returns the comma-separated fingerprints of the currently pending violations
      #
      # @return [String] The comma-separated list of fingerprints
      #
      def signoff_command
        @violations.map { |v| v['fingerprint'].to_s }.join(',')
      end


      #
      # Overridden version to take into account the fact that the report is due
      #   only if violations are pending
      #
      # @return [Boolean] Whether the report is due
      #
      def due?
        super && !violations.empty?
      end

    end
  end
end
