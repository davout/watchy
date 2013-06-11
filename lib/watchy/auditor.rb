require 'mysql2'

module Watchy
  class Auditor

    SLEEP_TIME = 1.0

    def initialize(config)
      @config = config
      l.warn "Booting Watchy #{Watchy::VERSION}"
      @conn = connect_db(@config[:db_server])
      prepare_databases!
    end

    def l
      @logger ||= @config[:logger]
    end

    def run!
      l.warn "Starting audit loop, interrupt with <Ctrl>-C ..."

      interrupted = false
      trap('INT') { interrupted = true }

      while(!interrupted) do
        copy_new_rows(@conn,

        # reporting = enforce_constraints
        # dispatch_alerts(reporting)
        # trigger_scheduled_tasks
        
        l.debug("Sleeping for #{SLEEP_TIME}s before next run...")
      end
    end

    def prepare_databases!
      # Check for audited schema
      watched_db = @config[:watched_db]
      unless schema_exists?(@conn, watched_db)
        raise "Audited DB #{watched_db} does not exist." 
      end

      # Check for audit schema
      audit_db = @config[:audit_db]
      unless schema_exists?(@conn, audit_db)
        create_db!(conn, audit_db)
      end

      # Check for presence of audit tables and create if necessary
      synchronize_tables!(@conn, watched_db, audit_db)
    end

    def schema_exists?(connection, db_name)
      connection.query('SHOW DATABASES').any? { |d| d['Database'] == db_name }
    end

    def connect_db(db, set_default_schema = true)
      params =  { host: db[:host], username: db[:username], password: db[:password], encoding: db[:encoding], database: db[:schema] }
      params.delete(:database) unless set_default_schema
      l.info "Connecting to #{set_default_schema && "#{db[:schema]}@" }#{db[:host]}:#{db[:port]}..."
      Mysql2::Client.new(params)
    end

    def create_db!(conn, db_name)
      conn.query("CREATE DATABASE `#{db_name}`")
    end

    def copy_table(conn, watched_db, audit_db, table)
      l.info "Copying table `#{table}` from watched to audit database"
      conn.query("CREATE TABLE `#{audit_db}`.`#{table}` LIKE `#{watched_db}`.`#{table}`")
      add_copied_at_field(conn, audit_db, table)
    end

    def add_copied_at_field(conn, db, table)
      l.info "Adding `#{table}`.`copied_at` audit field..."
      conn("ALTER TABLE `#{db}`.`#{table}` ADD `copied_at` TIMESTAMP NULL")
    end

    def copy_new_rows(conn, watched_db, audit_db, table, primary_key = :id)
      debug "Copying new rows into #{table} ..."

      pkey_equality_condition = "(#{[primary_key].flatten.map { |k| "`#{watched_db}`.`#{table}`.`#{k}` = `#{audit_db}`.`#{table}`.`#{k}`" }.join(' AND ')})"

      q = <<-EOF
        INSERT INTO `#{audit_db}`.`#{table}` 
          SELECT *, NULL 
          FROM `#{watched_db}`.`#{table}` 
          WHERE NOT EXISTS (
            SELECT * FROM `#{audit_db}`.`#{table}` WHERE #{pkey_equality_condition} 
          )
      EOF

      cnt = conn.query("SELECT COUNT(*) FROM `#{audit_db}`.`#{table}` WHERE `copied_at` IS NULL").to_a.flatten[0]
      info "Copied #{cnt} new rows."
      cnt
    end

    def synchronize_tables!(conn, watched_db, audit_db)
      audit_db_tables = conn.query("SHOW TABLES FROM `#{audit_db}`").to_a.map { |i| i.to_a.flatten[1] }
      audit_tables = @config[:watched_tables].keys.map(&:to_s)
      to_copy = audit_tables - audit_db_tables

      to_copy.each { |t| copy_table(conn, watched_db, audit_db, t) }

      audit_tables.each do |t|
        watched_table_fields = conn.query("DESC `#{watched_db}`.`#{t}`").to_a
        audit_table_fields = conn.query("DESC `#{audit_db}`.`#{t}`").to_a
        delta = watched_table_fields - audit_table_fields
        delta = [delta, (audit_table_fields - watched_table_fields).reject { |i| i['Field'] == 'copied_at' }  ].flatten

        if delta.empty?
          l.info "Audit table `#{t}` is up to date."
        else
          raise "Unable to continue, structure of audited and audit tables are different for table #{t}"
        end
      end
    end
  end
end
