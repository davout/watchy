#!/usr/bin/env ruby
# encoding: utf-8

require 'mysql2'
require 'net/smtp'

LOG_LEVEL = :debug
SLEEP     = 5
SEND_MAIL = false

CONFIG    = {
  db: {
    username: 'rails',
    password: 'rails',
    database: 'bitcoin-platform_dev',
    host: 'localhost',
    encoding: 'UTF8'
  },
  audit: {
    tables: {
      account_operations: [:amount, :type, :currency, :created_at, :account_id, :operation_id],
      operations: [:created_at, :type, :purchase_order_id, :sale_order_id]
    }
  }
}

interrupted = false

def notify_failure(message)
  message = <<-EOS
    From: AuditMatic <auditmatic@maine.paymium.com>
    To: Support <support@bitcoin-central.net>
    Subject: Audit failure

    Auditmatic has detected a change in previous data.
    Please send the the cavalry. Now.

    #{ message || "No specific message given." }

    Your faithful employee,
    AuditMatic
  EOS
  
  message = message.split("\n").map { |l| l =~ /[^\s]/ ? l.gsub(/^\s*/, '') : l }.join("\n")

  if SEND_MAIL
    Net::SMTP.start('localhost') do |smtp|
      smtp.send_message message, 'auditmatic@maine.paymium.com', 'support@bitcoin-central.net'
    end
  else
    warn("Unable to send e-mail :\n#{message}")
  end
end

trap('INT') do
  if interrupted
    fatal 'Forcing quit'
    exit(1)
  end

  interrupted = true
  warn 'Interrupted, finishing current run...'
end

def log(level, message)
  levels = [:debug, :info, :warn, :fatal]
  if levels.index(LOG_LEVEL) <= levels.index(level.to_sym)
    puts " -- #{Time.now.to_i} - #{level.upcase}#{' ' * (6 - level.length)} - #{message}" 
  end

  $stdout.flush
end

def debug(message)
  log('debug', message)
end

def info(message)
  log('info', message)
end

def warn(message)
  log('warn', message)
end

def fatal(message)
  log('fatal', message)
end

warn 'Starting audit daemon'

info 'Connecting to database'

db = Mysql2::Client.new(host: CONFIG[:db][:host], username: CONFIG[:db][:username], password: CONFIG[:db][:password], database: CONFIG[:db][:database], encoding: CONFIG[:db][:encoding])

info 'Connected'

debug 'Checking for audit database'

audit_db_name = "#{CONFIG[:db][:database]}_audit"
db_name       = "#{CONFIG[:db][:database]}"

audit_db_exists = db.query('SHOW DATABASES').any? do |d|
  d['Database'] == audit_db_name
end

unless audit_db_exists
  info 'Creating audit database'
  db.query("CREATE DATABASE `#{audit_db_name}`")
end

audit_db = Mysql2::Client.new(host: CONFIG[:db][:host], username: CONFIG[:db][:username], password: CONFIG[:db][:password], database: audit_db_name, encoding: CONFIG[:db][:encoding])

debug 'Checking audit tables'

tables = audit_db.query("SHOW TABLES")
tables = tables.map { |t| t.values[0] } 
audited_tables = CONFIG[:audit][:tables].keys.map(&:to_s)
audited_tables.each do |t|
  unless tables.include?(t)
    info "Missing #{t} table in audit DB #{audit_db_name}, creating."
    audit_db.query("CREATE TABLE `#{t}` LIKE `#{CONFIG[:db][:database]}`.`#{t}`")
  end
end

audited_tables.each do |at|
  debug "Checking for last_audit_at column presence in #{at}"

  r = audit_db.query("DESC `#{at}`")

  unless r.any? { |row| row['Field'] == 'last_audit_at' }
    info 'Adding last_audit_at column to audit tables'
    audit_db.query "ALTER TABLE `#{at}` ADD `last_audit_at` DATETIME"
  end
end

warn 'Starting continuous audit, press <Ctrl>-C to quit.'

while(!interrupted) do
  info 'Starting audit cycle'

  audit_fail = false
  failures   = []

  audited_tables.each do |at|
    info "Auditing #{at}..."

    debug "Copying new rows into #{at}..."
    q = <<-EOF
      INSERT INTO `#{at}` 
        SELECT *, NULL 
        FROM `#{db_name}`.`#{at}` 
        WHERE NOT EXISTS (
          SELECT * FROM `#{at}` WHERE `#{at}`.`id` = `#{db_name}`.`#{at}`.`id`
        )
    EOF

    debug "Executing query :\n#{q}"
    audit_db.query(q)
    r = audit_db.query "SELECT COUNT(*) FROM `#{at}` WHERE last_audit_at IS NULL"

    if r.first['COUNT(*)'].to_i > 0 
      warn "Copied #{r.first['COUNT(*)']} new rows to the #{at} audit table"
    else
      debug "No new rows copied"
    end

    audit_filter = CONFIG[:audit][:tables][at.to_sym].inject([]) do |acc, i|0
    acc << "((audit_table.`#{i}` <> audited_table.`#{i}`) OR (audited_table.`#{i}` IS NULL AND audit_table.`#{i}` IS NOT NULL) OR (audited_table.`#{i}` IS NOT NULL AND audit_table.`#{i}` IS  NULL))"
    end.join(' OR ')

    audit_query = <<-EOS
      SELECT *
      FROM `#{at}` audit_table INNER JOIN `#{db_name}`.`#{at}` audited_table ON audited_table.id = audit_table.id
      WHERE #{audit_filter}
      EOS

      debug "Executing query :\n#{audit_query}"

      r = audit_db.query audit_query

      r.each do |row|
        audit_fail = true
        failures <<  "Row ##{row['id']} in #{at} changed since last audit (at #{row['last_audit_at']}) !" 
      end

      missing_rows_query = <<-EOS
      SELECT *
      FROM `#{at}` audit_table
      WHERE
        NOT EXISTS (SELECT * FROM `#{db_name}`.`#{at}` audited_table WHERE audited_table.id = audit_table.id) 
      EOS

      debug "Executing query :\n#{missing_rows_query}"

      r = audit_db.query missing_rows_query

      r.each do |row|
        audit_fail = true
        failures << "Row ##{row['id']} in #{at} has been deleted from audited table!"
      end

      inserted_rows_query = <<-EOS
        SELECT *
        FROM `#{db_name}`.`#{at}` audited_table
        WHERE 
          audited_table.id < (SELECT MAX(id) FROM `#{at}`) AND
          NOT EXISTS (SELECT * FROM #{at} audit_table WHERE audit_table.id = audited_table.id)
      EOS

      debug "Executing query :\n #{inserted_rows_query}"

      r = audit_db.query inserted_rows_query

      r.each do |row|
        audit_fail = true
        failures << "Row ##{row['id']} was inserted in an ID gap on the production database"
      end

      audit_db.query("UPDATE `#{at}` SET `last_audit_at` = NOW() WHERE `last_audit_at` IS NULL") unless audit_fail
  end

  if audit_fail
    failures.each { |f| fatal f }
    fatal "Audit failed !"
    notify_failure(failures.join("\n"))
    exit(1)
  else
    info "Audit OK."
  end

  if SLEEP && SLEEP > 0
    debug("Sleeping for #{SLEEP}s")
    sleep(SLEEP)
  end
end
