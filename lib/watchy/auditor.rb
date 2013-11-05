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

      setup_snapshots(config[:snapshots])

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

        # Flags the rows that have changed since the last audit loop
        flag_row_deltas

        # Copies rows that were inserted in the watched tables
        copy_new_rows

        # Check if deletions happened on the watched tables
        check_deletions

        # Enforce the different rules on the relevant items
        check_rules

        # Runs the periodic tasks that are due
	run_periodic_tasks!

        # Timestamps the newly inserted rows
        stamp_new_rows

        # Copies modifications of the watched tables to the audit tables
        update_audit_tables

        # Records a version of the rows that have changed in the watched tables
        version_flagged_rows

        # Reset the "row has changed" flag
        unflag_row_deltas

        # Receives messages from the queue and executes them
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
    # Runs the due periodic tasks
    #
    def run_periodic_tasks!
      logger.warn("Running periodic tasks...")
      PeriodicTask.run_all_due!
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
    # Sets up the DB snapshotting tasks
    #
    def setup_snapshots(snapshots)
      snapshots && snapshots.each do |s|
        PeriodicTask.new(s[1]) { take_snapshot(s[0]) }
      end
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
