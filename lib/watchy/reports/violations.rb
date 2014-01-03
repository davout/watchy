require 'watchy/report'

module Watchy

  #
  # This module contains the implementations of the standard reports
  #   that should be used in all watchy setups
  #
  module Reports

    #
    # The maximum amount of violations to report at once
    #
    MAX_REPORTED_VIOLATIONS = 50

    #
    # This report lists currently active rule violations, it is sent every
    #   ten minutes if violations are present.
    #
    class Violations < Watchy::Report

      #
      # The default crondef is every hour
      #
      def initialize(crondef = nil)
        super(crondef || '0 * * * *')
      end

      #
      # The report template contents as a string
      #
      # @return [String] The temaplate contents
      #
      def template
        File.read(File.expand_path('../../../../templates/violations.md.mustache', __FILE__))
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
      # The violations currently in 'PENDING' state
      #
      # @return [Array<Hash>] The currently active violations
      #
      def violations
        db.query("SELECT * FROM `#{audit_db}`.`_rule_violations` WHERE `state` = 'PENDING' LIMIT #{MAX_REPORTED_VIOLATIONS}").to_a
      end

      #
      # Returns the comma-separated fingerprints of the currently pending violations
      #
      # @return [String] The comma-separated list of fingerprints
      #
      def signoff_command
        violations.map { |v| v['fingerprint'].to_s }.join(',')
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
