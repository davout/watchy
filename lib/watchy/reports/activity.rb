require 'watchy/report'

module Watchy

  module Reports

    #
    # This report shows statistics on activity that happened
    #   recently such as insertions, deletions, updates
    #
    class Activity < Watchy::Report

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
                action: 'insert',
                value: db.query("SELECT COUNT(*) AS CNT FROM #{table.audit} WHERE `copied_at` >= #{cutoff}").to_a[0]['CNT']
              },
              {
                action: 'delete',
                value: db.query("SELECT COUNT(*) AS CNT FROM #{table.audit} WHERE `deleted_at` >+ #{cutoff}").to_a[0]['CNT']
              }
            ]
          }
        end

        act
      end

      def cutoff
        DateTime.now.advance(hours: -HOURS).strftime('%Y-%m-%d %H:%M:%S')
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
