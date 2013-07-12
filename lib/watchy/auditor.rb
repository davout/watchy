require 'watchy/schema_helper'
require 'watchy/tables_helper'
require 'watchy/database_helper'
require 'watchy/logger_helper'
require 'watchy/table'
require 'watchy/report'
require 'watchy/gpg'

module Watchy

  #
  # An auditor continuously watches +watched_db+ and enforces a set of user-defined rules on its data
  #
  class Auditor

    include Watchy::SchemaHelper
    include Watchy::TablesHelper
    include Watchy::DatabaseHelper
    include Watchy::LoggerHelper

    attr_accessor :config, :watched_db, :audit_db, :interrupted, :reports

    #
    # Initializes an +Auditor+ instance given the current configuration.
    # Bootstraps the audit database if necessary.
    #
    def initialize(configuration)
      self.config = configuration

      logger.info "Booting Watchy #{Watchy::VERSION}"

      @watched_db ||= config[:database][:schema]
      @audit_db   ||= config[:database][:audit_schema]
      @reports    ||= [config[:reports]].flatten.compact

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

      while(!interrupted) do
        loop_start = Time.now

        flag_row_deltas
        
        check_rules

        copy_new_rows

        # dispatch_alerts(reporting)
        # trigger_scheduled_tasks

        run_reports!
        stamp_new_rows
        # check_deletions

        unflag_row_deltas

        logger.info("Last loop took #{"%.2f" % (Time.now - loop_start)}s")
        logger.debug("Sleeping for #{config[:sleep_for]}s before next run ...")
        sleep(config[:sleep_for]) unless interrupted
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
    # Resets the +has_delta+ flag
    #
    def unflag_row_deltas
      tables.each(&:unflag_row_deltas)
    end

    #
    # Flags the rows that are different in the audited and audit DBs in
    #   order to run the various audit rules against them
    #
    def flag_row_deltas
      tables.each(&:flag_row_deltas)
    end

    #
    # Enforces the constraints defined on the watched tables
    #
    def check_rules
      tables.each(&:check_rules_on_update)
      tables.each(&:check_rules_on_insert)
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
