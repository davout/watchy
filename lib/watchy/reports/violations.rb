require 'watchy/report'

module Watchy
  module Reports
    
    #
    # This report lists currently active rule violations, it is sent every
    #   ten minutes if violations are present.
    #
    class Violations < Watchy::Report

      #
      # The report template
      #
      def template
        File.read(File.expand_path('../../../../templates/violations.md.mustache', __FILE__))
      end

      #
      # The generation time
      #
      def generated_at
        Time.now
      end

      #
      # The currently active violations
      #
      def violations
        db.query("SELECT * FROM `#{audit_db}`.`_rule_violations` WHERE `state` = 'PENDING'").to_a
      end


      #
      # Overridden version to take into account the fact that the report is due
      #   only if violations are pending
      #
      def due?
        super && violations_present?
      end
    end
  end
end
