require 'watchy/schema_helper'
require 'watchy/tables_helper'
require 'watchy/database_helper'
require 'watchy/logger_helper'
require 'watchy/table'
require 'watchy/report'

module Watchy

  #
  # An auditor continuously watches +watched_db+ and enforces a set of user-defined rules on its data
  #
  class Auditor

    include Watchy::SchemaHelper
    include Watchy::TablesHelper
    include Watchy::DatabaseHelper
    include Watchy::LoggerHelper

    attr_accessor :tables, :watched_db, :audit_db, :interrupted, :reports

    #
    # Initializes an +Auditor+ instance given the current configuration.
    # Bootstraps the audit database if necessary.
    #
    def initialize
      logger.info "Booting Watchy #{Watchy::VERSION}"

      @watched_db ||= Settings[:watched_db]
      @audit_db   ||= Settings[:audit_db]

      @tables ||= Settings[:watched_tables].keys.map { |k| Table.new(self, k.to_s) }
      @reports ||= [Settings[:reports]].flatten 

      bootstrap_databases!
      bootstrap_audit_tables!

      logger.info "Watching '#{watched_db}', using '#{audit_db}' as audit database"

      trap('INT') { interrupt! }
    end

    #
    # Runs audit cycles until interrupted by a SIGTERM
    #
    def run!
      logger.info "Starting audit loop, interrupt with <Ctrl>-C ..."

      sleep_for = Settings[:sleep_for]

      while(!interrupted) do
        copy_new_rows

        # reporting = enforce_constraints
        # dispatch_alerts(reporting)
        # trigger_scheduled_tasks

        run_reports!

        stamp_new_rows

        logger.debug("Sleeping for #{sleep_for}s before next run ...")
        sleep(sleep_for) unless interrupted
      end
    end

    #
    # Copies the new rows from the audited database for each audited table
    #
    def copy_new_rows
      tables.each(&:copy_new_rows)
    end

    #
    # Timestamps the new rows in the audit database at the end of the audit cycle
    #
    def stamp_new_rows
      tables.each(&:stamp_new_rows)
    end

    #
    # Runs the configured reports if necessary
    #
    def run_reports!
      reports.map(&:run).compact
    end

    #
    # Enforces the constraints defined on the watched tables
    #
    def enforce_constraints
      tables.each(&:enforce_constraints)
    end

    #
    # Interrupts the auditing loop
    #
    def interrupt!
      @interrupted = true
      logger.info "Interrupted, terminating..."
    end
  end
end
