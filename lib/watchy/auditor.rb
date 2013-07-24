require 'watchy/schema_helper'
require 'watchy/tables_helper'
require 'watchy/database_helper'
require 'watchy/logger_helper'
require 'watchy/table'
require 'watchy/report'
require 'watchy/gpg'
require 'watchy/message'

module Watchy

  #
  # An auditor continuously watches +watched_db+ and enforces a set of user-defined rules on its data
  #
  class Auditor

    include Watchy::SchemaHelper
    include Watchy::TablesHelper
    include Watchy::DatabaseHelper
    include Watchy::LoggerHelper

    attr_accessor :config, :watched_db, :audit_db, :interrupted

    #
    # Initializes an +Auditor+ instance given the current configuration.
    # Bootstraps the audit database if necessary.
    #
    # @param configuration [Hash] The configuration hash
    #
    def initialize(configuration)
      self.config = configuration

      logger.info "Booting Watchy #{Watchy::VERSION}"

      @watched_db       ||= config[:database][:schema]
      @audit_db         ||= config[:database][:audit_schema]
      @reports          ||= config[:reports]
      @receive_queue    ||= config[:receive_queue]
      @broadcast_queue  ||= config[:broadcast_queue]

      if config[:gpg]
        @receive_queue.gpg    = config[:gpg] if @receive_queue
        @broadcast_queue.gpg  = config[:gpg] if @broadcast_queue
      end

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
        copy_new_rows
        check_deletions
        check_rules

        # dispatch_alerts(reporting)
        # trigger_scheduled_tasks
        run_reports!
        stamp_new_rows
        update_audit_tables
        version_flagged_rows
        unflag_row_deltas

        receive_and_handle_messages

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
      @reports.select(&:due?).each do |r|
        logger.warn("Generating report '#{r.class}'")
        r.broadcast!
      end
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
    # Versions rows that have been updated
    #
    def version_flagged_rows
      tables.each(&:version_flagged_rows)
    end

    #
    # Checks whether deletions happened in the watched schema
    #
    def check_deletions
      tables.each(&:check_deletions)
    end

    #
    # Enforces the constraints defined on the watched tables
    #
    def check_rules
      tables.each(&:check_rules_on_update)
      tables.each(&:check_rules_on_insert)
    end

    #
    # Updates the audit schema with the rows that have changed in the 
    #   watched database
    #
    def update_audit_tables
      tables.each(&:update_audit_table)
    end

    #
    # Receives as much messages as are present in the queue and calls
    #   their appropriate message handler
    #
    def receive_and_handle_messages(max_count = 10)
      logger.debug("Receiving messages from queue (max: #{max_count})")

      msg_count = 0
      msg = nil
      
      while (msg = @receive_queue.pop) && (msg_count <= max_count)
        Watchy::Message.handle(msg)
        msg_count += 1
      end

      logger.info("Received #{msg_count} messages")
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
