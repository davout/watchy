require 'watchy/schema_helper'
require 'watchy/tables_helper'
require 'watchy/table'

module Watchy
  class Auditor

    include Watchy::SchemaHelper
    include Watchy::TablesHelper

    attr_accessor :tables, :logger, :connection, :watched_db, :audit_db

    def initialize
      @logger = Watchy.logger
      logger.info "Booting Watchy #{Watchy::VERSION}"

      @connection = Watchy.connection

      @watched_db = Settings[:watched_db]
      @audit_db   = Settings[:audit_db]

      @tables = Settings[:watched_tables].keys.map { |k| Table.new(self, k.to_s) }

      bootstrap_databases!
      bootstrap_audit_tables!
    end

    def run!
      logger.info "Starting audit loop, interrupt with <Ctrl>-C ..."

      sleep_for = Settings[:sleep_for]

      interrupted = false
      trap('INT') { interrupted = true }

      while(!interrupted) do
        tables.each { |t| t.copy_new_rows } 

        # reporting = enforce_constraints
        # dispatch_alerts(reporting)
        # trigger_scheduled_tasks

        tables.each { |t| t.stamp_new_rows } 

        logger.debug("Sleeping for #{sleep_for}s before next run ...")
        sleep(sleep_for) unless interrupted
      end
    end
  end
end
