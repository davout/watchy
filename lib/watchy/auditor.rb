require 'watchy/schema_helper'
require 'watchy/tables_helper'
require 'watchy/database_helper'
require 'watchy/logger_helper'
require 'watchy/table'

module Watchy
  class Auditor

    include Watchy::SchemaHelper
    include Watchy::TablesHelper
    include Watchy::DatabaseHelper
    include Watchy::LoggerHelper

    attr_accessor :tables, :connection, :watched_db, :audit_db, :interrupted

    def initialize
      logger.info "Booting Watchy #{Watchy::VERSION}"

      @watched_db ||= Settings[:watched_db]
      @audit_db   ||= Settings[:audit_db]

      @tables ||= Settings[:watched_tables].keys.map { |k| Table.new(self, k.to_s) }

      bootstrap_databases!
      bootstrap_audit_tables!

      trap('INT') { @interrupted = true }
    end

    def run!
      logger.info "Starting audit loop, interrupt with <Ctrl>-C ..."

      sleep_for = Settings[:sleep_for]

      while(!interrupted) do
        copy_new_rows

        # reporting = enforce_constraints
        # dispatch_alerts(reporting)
        # trigger_scheduled_tasks

        stamp_new_rows

        logger.debug("Sleeping for #{sleep_for}s before next run ...")
        sleep(sleep_for) unless interrupted
      end
    end

    def copy_new_rows
      tables.each { |t| t.copy_new_rows } 
    end

    def stamp_new_rows
      tables.each { |t| t.stamp_new_rows } 
    end
  end
end
