require 'watchy/field'
require 'forwardable'
require 'base64'
require 'json'

module Watchy

  #
  # Represents an audited table
  #
  class Table

    include Watchy::DatabaseHelper

    extend Forwardable

    def_delegator self, :condition_from_hashes 
    def_delegator self, :assignment_from_hash

    #
    # The field names used internally for auditing
    #
    METADATA_FIELDS = %w{ _copied_at _has_delta _last_version _has_violation _deleted_at }

    attr_accessor :name, :columns, :auditor, :db, :logger, :rules, :versioning_enabled

    #
    # Initializes a table given an +auditor+ and a +name+
    #
    # @param auditor [Watchy::Auditor] The current +Watchy::Auditor+ instance
    # @param name [String] The table name in the audited schemai
    # @param rules [Hash] The hash of rules to enforce for this table
    # @param versioning_enabled [Boolean] Whether to keep an history of all
    #   INSERTs, UPDATEs, and DELETEs for this table
    #
    def initialize(auditor, name, rules, versioning_enabled = false)
      @db         = auditor.db
      @logger             = auditor.logger
      @auditor            = auditor
      @rules              = rules
      @name               = name
      @versioning_enabled = versioning_enabled
    end

    #
    # Returns the quoted fully qualified name of the table in the audited schema
    #
    # @return [String] The fully qualified name as a string 
    #
    # == Examples
    #   
    #   table.watched
    #   => "`audited_db`.`audited_table`"
    #
    def watched
      identifier(watched_db) 
    end

    #
    # Returns the quoted fully qualified name of the table in the audit schema
    #
    # @return [String] The fully qualified name as a string 
    #
    # == Examples
    #   
    #   table.audit
    #   => "`audit_db`.`audited_table`"
    #
    def audit
      identifier(audit_db)
    end

    #
    # Returns the quoted fully qualified name of the versioning table in the audit schema
    #
    # @return [String] The fully qualified name as a string 
    #
    # == Examples
    #   
    #   table.versioning
    #   => "`audit_db`.`_v_audited_table`"
    #
    def versioning
      identifier(audit_db, "_v_#{name}")
    end

    # 
    # Creates a quoted fully qualifed table name given a schema name
    #
    # @param schema [String] The schema name
    # @return [String] The quoted fully qualified table name
    #
    # == Examples
    #
    #   table.identifier('foo')
    #   => "`foo`.`table_name`"
    #
    def identifier(schema, name = nil)
      name ||= @name
      "`#{schema}`.`#{name}`"
    end

    #
    # Return an array containing the fields part of the table primary key
    #
    # @return [Array<Watchy::Field>] The primary key field names
    #
    # == Examples
    #
    #  table.primary_key
    #  => ["id"]
    #
    def primary_key
      fields.select { |f| f.key }.map(&:name)
    end

    #
    # Tests whether the table exists in the *audit* schema (the table
    # is always supposed to exist in the audited schema)
    #
    # @return [Boolean] Whether the audit table exists
    #
    def exists?
      Table.exists?(db, auditor.audit_db, name)
    end

    #
    # Copies the table structure from the audited schema to the audit one.
    #
    def copy_structure
      logger.info "Copying structure for table #{name} from watched to audit database"
      db.query("CREATE TABLE #{audit} LIKE #{watched}")
      add_copied_at_field
      add_has_delta_field
      add_last_version_field
      add_has_violation_field
      add_deletion_flag
    end

    # 
    # Checks the audit table structure for structure differences with the audited table. 
    # If the structures are different an exception is raised.
    # 
    def check_for_structure_changes!
      watched_fields = db.query("DESC #{watched}").to_a
      audit_fields   = db.query("DESC #{audit}").to_a
      delta = watched_fields - audit_fields
      delta = [delta, (audit_fields - watched_fields).reject { |i| METADATA_FIELDS.include?(i['Field']) }].flatten
      metadata_present = METADATA_FIELDS.all? { |f| (audit_fields - watched_fields).map { |i| i['Field'] }.include?(f) }

      if !delta.empty?
        raise "Structure has changed for table '#{name}'!"
      elsif !metadata_present
        missing_fields = METADATA_FIELDS - (audit_fields - watched_fields).map { |i| i['Field'] }
        raise "Missing meta-data fields in audit table '#{name}' : #{missing_fields.join(', ')}."
      else
        logger.info "Audit table #{name} is up to date."
      end
    end

    # 
    # Adds a +_deleted_at BIGINT NULL+ field to the audit table
    #
    def add_deletion_flag
      logger.info "Adding #{name}._deleted_at audit field..."
      db.query("ALTER TABLE #{audit} ADD `_deleted_at` BIGINT NULL")
    end

    # 
    # Adds a +_copied_at TIMESTAMP NULL+ field to the audit table
    #
    def add_copied_at_field
      logger.info "Adding #{name}._copied_at audit field..."
      db.query("ALTER TABLE #{audit} ADD `_copied_at` TIMESTAMP NULL")
    end

    #
    # Adds a +_has_delta TINYINT NOT NULL DEFAULT 0+ field to the audit table
    #
    def add_has_delta_field
      logger.info "Adding #{name}._has_delta audit field..."
      db.query("ALTER TABLE #{audit} ADD `_has_delta` TINYINT NOT NULL DEFAULT 0")
    end

    #
    # Adds a +_last_version+ BIGINT NULL+ field to the audit table
    #
    def add_last_version_field
      logger.info "Adding #{name}._last_version audit field..."
      db.query("ALTER TABLE #{audit} ADD `_last_version` BIGINT NULL") 
    end

    #
    # Adds a +_has_violation TINYINT NOT NULL DEFAULT 0+ to the audit table
    #
    def add_has_violation_field
      logger.info "Adding #{name}._has_violation audit field..."
      db.query("ALTER TABLE #{audit} ADD `_has_violation` TINYINT NOT NULL DEFAULT 0") 
    end

    #
    # Timestamp rows after they have been copied by updating the +copied_at+ field in the
    # audit table with the current timestamp.
    #
    def stamp_new_rows
      db.query("UPDATE #{audit} SET `_copied_at` = NOW() WHERE `_copied_at` IS NULL")
    end

    #
    # Copies new rows from the audited table to the audit table. It uses the +primary_key+ method
    # to join the audited and audit tables and copy only rows that exist in the audited table
    # but not in the audit one.
    #
    def copy_new_rows
      logger.debug "Copying new rows into #{name} ..."

      q = <<-EOF 
        INSERT INTO #{audit} 
          SELECT #{watched}.*, NULL, 0, NULL, 0, NULL
          FROM #{watched} LEFT JOIN #{audit} ON #{pkey_equality_condition} 
          WHERE #{audit}.`_last_version` IS NULL
      EOF

      db.query(q)
      cnt = db.query("SELECT COUNT(*) FROM #{audit} WHERE `_copied_at` IS NULL").to_a[0].flatten.to_a[1]
      logger.info "Copied #{cnt} new rows for table #{name}."

      version_inserted_rows if cnt > 0

      cnt
    end

    #
    # Inserts the initial row in the version-tracking table
    #
    def version_inserted_rows
      if versioning_enabled
        logger.warn "Inserting initial version for inserted rows in '#{name}'"

        last_version = Time.now.to_i

        q_versioning = <<-EOF
          INSERT INTO #{versioning} 
            SELECT #{fields.map(&:audit).join(', ')}, #{last_version} 
            FROM #{audit} 
            WHERE #{audit}.`_copied_at` IS NULL
        EOF

        q_audit_update = "UPDATE #{audit} SET `_last_version`= #{last_version} WHERE `_copied_at` IS NULL"

        db.query(q_versioning)
        db.query(q_audit_update)
      end
    end

    #
    # Flags the rows that are different in the audited and audit DBs, the rows are flagged
    #   so that the constraints defined to be checked on updates are properly enforced
    #
    def flag_row_deltas
      logger.debug "Flagging row deltas for #{name}"

      q = "SELECT #{pkey_selection(audit)} FROM #{audit} INNER JOIN #{watched} ON #{pkey_equality_condition} WHERE #{differences_filter}"
      r = db.query(q).to_a

      unless r.count.zero?
        q = "UPDATE #{audit} SET `_has_delta` = 1 WHERE #{condition_from_hashes(r, audit)}"
        db.query(q) 
        logger.warn "Flagged #{r.count} rows for check in #{name}" 
      end
    end

    #
    # Versions the rows that have changed since the last audit loop
    #
    def version_flagged_rows
      if versioning_enabled

        logger.debug "Inserting new row versions for flagged rows"

        last_version = Time.now.to_i

        q_versioning = <<-EOF
          INSERT INTO #{versioning} 
            SELECT #{fields.map(&:audit).join(', ')}, #{last_version} 
            FROM #{audit} 
            WHERE #{audit}.`_has_delta` = 1
        EOF

        q_audit_update = "UPDATE #{audit} SET `_last_version` = #{last_version} WHERE `_has_delta` = 1"

        db.query(q_versioning)
        db.query(q_audit_update)
      end
    end

    #
    # Resets the delta flag, at the end of each auditing loop
    #
    def unflag_row_deltas
      logger.debug "Resetting row delta flags for #{name}"
      q = "UPDATE #{audit} SET `_has_delta` = 0"
      db.query(q)
    end

    #
    # Updates the audit schema with the changes that happened in the
    #   watched database, this happens after all rules have been run
    #   and versions copied.
    #
    # If versioning is disabled and a rule violation is detected during
    #   the audit process the row isn't updated so no information ever
    #   gets lost.
    #
    def update_audit_table
      logger.info "Updating audit schema with modifications in table '#{name}'"

      unversioned_filter = versioning_enabled ? '1 = 1' : '`_has_violation` = 0' 

      q_rows_to_update = <<-EOS
        SELECT #{pkey_selection(audit)} 
        FROM #{audit} 
        WHERE `_has_delta`= 1 AND #{unversioned_filter} 
      EOS

      db.query(q_rows_to_update).each do |row|
        watched_row = db.query("SELECT * FROM #{watched} WHERE #{condition_from_hashes(row)}").to_a[0]
        db.query("UPDATE #{audit} SET #{assignment_from_hash(watched_row)} WHERE #{condition_from_hashes(row)}")
      end
    end

    #
    # Enforces all the defined rules and constraints on the rows flagged
    #   as having deltas when compared to the original rows.  Each constraint 
    #   violation gets logged in order to be reported upon.
    #
    def check_rules_on_update
      logger.debug "Running UPDATE checks for #{name}"

      db.query("SELECT * FROM #{audit} WHERE `_has_delta` = 1").each do |audit_row|
        pkey = audit_row.select { |k,v| primary_key.include?(k) }
        logger.debug "Checking row: #{pkey}"

        watched_row_query = "SELECT * FROM #{watched} WHERE #{condition_from_hashes(pkey)}"
        watched_row = db.query(watched_row_query).first

        # If we do not have a matched row here it'll show in the deletion checks, so we
        # do nothing specific here
        if watched_row
          fields.each do |f|
            violations = f.on_update(audit_row, watched_row)
            violations.compact.each { |v| record_violation(v[:description], audit_row, v[:rule_name], audit_row['_last_version'], f.name) }
          end

          rules[:update].each do |rule|
            v = rule.execute(audit_row, watched_row, self)
            record_violation(v, [watched_row, audit_row], rule.name, audit_row['_last_version']) if v
          end
        end
      end
    end

    #
    # Enforces all the defined rules and constraints on the new rows.
    #   Each constraint violation gets logged in order to be reported upon.
    #
    def check_rules_on_insert
      logger.debug "Running INSERT checks for #{name}"

      db.query("SELECT * FROM #{audit} WHERE `_copied_at` IS NULL").each do |audit_row|
        pkey = audit_row.select { |k,v| primary_key.include?(k) }
        logger.debug "Checking row: #{pkey}"

        fields.each do |f|
          violations = f.on_insert(audit_row)
          violations.compact.each { |v| record_violation(v[:description], v[:item], v[:rule_name], audit_row['_last_version'], f.name) }
        end

        rules[:insert].each do |rule|
          v = rule.execute(audit_row, self)
          record_violation(v, audit_row, rule.name, audit_row['_last_version']) if v
        end
      end
    end

    #
    # Checks the deletions that happened on the watched table
    #
    def check_deletions
      logger.debug "Checking for deletions in table #{name}"

      q_find_deletions = <<-EOS
        SELECT #{pkey_selection(audit)} 
        FROM   #{audit} LEFT JOIN #{watched} ON #{pkey_equality_condition} 
        WHERE
          #{watched}.#{primary_key.first} IS NULL AND
          `_deleted_at` IS NULL
      EOS

      deletions = db.query(q_find_deletions).to_a

      if deletions.count > 0
        deletions.each do |del|
          row = db.query("SELECT * FROM #{audit} WHERE #{condition_from_hashes(del)}").to_a[0]
          rules[:delete].each do |rule|
            v = rule.execute(row, self)
            record_violation(v, row, rule.name, row['_last_version']) if v
          end
        end

        q_flag_deletions = "UPDATE #{audit} SET `_deleted_at` = #{Time.now.to_i} WHERE #{condition_from_hashes(deletions)}"
        db.query(q_flag_deletions)
        logger.warn "Flagged #{deletions.count} deletions"
      end
    end

    #
    # Records rule violations in the '_rule_violations' table. A rule violation
    #   is saved only if there is no other pending record for the same +rule_name+
    #   value.
    #
    # @param violation [String] The rule violation description
    # @param item [Hash] The row as hash
    # @param rule_name [String] The rule name
    # @param row_version [Fixnum] The row version for which this violation was detected 
    #
    def record_violation(violation, item, rule_name, row_version, field = nil)
      stamp = Time.now.to_i

      serialized = assignment_from_hash(item)
      pk = item.select { |k,v| primary_key.include?(k.to_s) }

      fingerprint = Digest::SHA2.hexdigest("#{pk}-#{name}-#{rule_name}-#{field}-#{violation}-#{row_version}")

      field_condition = field ? "`field` = '#{field}'" : "1 = 1" 

      q_already_exists = <<-EOS
        SELECT COUNT(*) AS CNT 
        FROM `#{auditor.audit_db}`.`_rule_violations` 
        WHERE  
          #{field_condition} AND
          `pkey` = '#{db.escape(JSON.dump(pk))}' AND 
          `audited_table` = '#{name}' AND
          `state` = 'pending' AND
          `name` = '#{rule_name}'
      EOS

      already_exists = db.query(q_already_exists).to_a[0]['CNT'] > 0

      q = <<-EOF
        INSERT INTO `#{auditor.audit_db}`.`_rule_violations` 
          (`fingerprint`, `audited_table`, `field`, `name`, `stamp`, `description`, `item`, `pkey`, `row_version`, `state`)
        VALUES 
          ('#{fingerprint}', '#{name}', #{ field ? "'#{field}'" : 'NULL' }, '#{rule_name || ''}',
      #{stamp}, '#{db.escape(violation)}', '#{db.escape(serialized)}', '#{db.escape(JSON.dump(pk))}', #{row_version}, 'PENDING')
      EOF

      if !already_exists
        logger.error "Recording violation [#{fingerprint[0..16]}] for '#{rule_name}' ('#{name}'.'#{field}') at #{stamp}"
        db.query(q)
      end

      db.query("UPDATE #{audit} SET `_has_violation` = 1 WHERE #{condition_from_hashes(pk)}")
    end

    #
    # Return the table's fields
    #
    # @return [Array] An array of the table's fields
    #
    def fields(for_db = :watched)
      @fields ||= db.query("DESC #{send(for_db)}").map do |f|
        Watchy::Field.new(
          self,
          f['Field'],
          f['Type'],
          f['Null'],
          f['Key'] == 'PRI',
          f['Default'],
          f['Extra']
        )
      end
    end

    #
    # Returns the filter used to check for differences among previously copied rows
    #
    # @return [String] A +WHERE+ clause fragment matching when rows have differences
    #
    def differences_filter
      conditions = fields.map { |field| "(#{field.difference_filter})" }
      "(#{conditions.join(' OR ')})"
    end

    #
    # Returns the primary key fields as a string directly usable in a +SELECT+ clause
    #
    # @param table [String] The table alias to use for prefixing the identifier, may be omitted
    # @return [String] The +SELECT+ compatible field list
    #
    def pkey_selection(table = nil)
      prefix = table ? "#{table}." : ""
      "#{primary_key.map { |k| "#{prefix}`#{k}` AS '#{k}'" }.join(', ')}"
    end

    #
    # Returns the primary key equality condition
    #
    # @return [String] A SQL fragment used as +INNER JOIN+ condition to join the watched and audited tables
    #
    def pkey_equality_condition
      "(#{primary_key.map { |k| "#{watched}.`#{k}` = #{audit}.`#{k}`" }.join(' AND ')})"
    end

    #
    # Returns a SQL +WHERE+ condition given an array of hashes containing field names
    #   as keys and constrained values as values
    #
    # @param p [Array<Hash>] Hash or array of conditions expressed as hashes
    # @param table [String] The table alias to use for prefixing the identifier, may be omitted
    # @return [String] A SQL +WHERE+ fragment
    #
    def self.condition_from_hashes(p, table = nil)
      prefix = table ? "#{table}." : ""

      cond_or = [p].flatten.map do |h|
        cond_and = h.map do |k,v|
          if v && !METADATA_FIELDS.include?(k)
            "#{prefix}`#{k}` = #{escaped_value(v)}"
          end
        end.compact

        "(#{cond_and.join(' AND ')})"
      end

      "(#{cond_or.join(' OR ')})"
    end

    #
    # Returns the SQL UPDATE fragment assigning the values to the fields passed
    #   as hash
    #
    # @param h [Hash] The keys and values to output as a SQL assignement fragment
    # @param table [String] The table alias to use for prefixing the identifier, may be omitted
    # @return [String] The +UPDATE table SET [...]+ fragment
    #
    def self.assignment_from_hash(h, table = nil)
      prefix = table ? "#{table}." : ""
      h.map do |k,v|
        unless METADATA_FIELDS.include?(k)
          "#{prefix}`#{k}` = #{escaped_value(v)}"
        end
      end.compact.join(', ')
    end

    # 
    # Escapes +String+ values with simple quotes
    #
    # @param o [Object] An object which may require its string representation to be escaped for SQL
    # @return [String] The escaped string representation of the object
    #
    def self.escaped_value(o)
      if o.nil?
        "NULL"
      elsif o.is_a?(Time) || o.is_a?(Date) 
        "'#{o}'"
      elsif o.is_a?(String)
        "'#{DatabaseHelper.db.escape(o)}'"
      else
        o.to_s
      end
    end

    #
    # Tests whether the table exists in the given schema
    #
    # @param db [Mysql2::Client] The database db to use
    # @param schema [String] The schema in which the table existence should be checked
    # @param table [String] The table name whose existence should be checked
    # @return [Boolean] Whether the audit table exists
    #
    def self.exists?(db, schema, table)
      db.query("SHOW TABLES FROM `#{schema}`").to_a.map { |i| i.to_a.flatten[1] }.include?(table)
    end

    #
    # Creates the versioning table in the audit schema
    #
    def create_versioning_table
      logger.info "Creating versioning table '_v_#{name}' in the audit schema"
      db.query("CREATE TABLE #{versioning} LIKE #{watched}")
      db.query("ALTER TABLE #{versioning} ADD `_row_version` BIGINT NOT NULL DEFAULT 0")
      db.query("ALTER TABLE #{versioning} DROP PRIMARY KEY, ADD PRIMARY KEY (#{([primary_key] << '_row_version').flatten.join(',')})")

      db.query("SHOW CREATE TABLE #{versioning}").to_a[0]['Create Table'].scan(/UNIQUE KEY `([^`]+)`/).flatten.each do |idx|
        db.query("ALTER TABLE #{versioning} DROP INDEX `#{idx}`")
      end
    end

  end
end
