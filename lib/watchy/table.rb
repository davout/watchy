require 'watchy/field'
require 'base64'

module Watchy

  #
  # Represents an audited table
  #
  class Table

    #
    # The field names used internally for auditing
    #
    METADATA_FIELDS = %w{ _copied_at _has_delta }

    attr_accessor :name, :columns, :auditor, :connection, :logger, :rules

    #
    # Initializes a table given an +auditor+ and a +name+
    #
    # @param auditor [Watchy::Auditor] The current +Watchy::Auditor+ instance
    # @param name [String] The table name in the audited schema
    #
    def initialize(auditor, name, rules)
      @connection = auditor.connection
      @logger     = auditor.logger
      @auditor    = auditor
      @rules      = rules
      @name       = name
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
      identifier(auditor.watched_db) 
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
      identifier(auditor.audit_db)
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
    def identifier(schema)
      "`#{schema}`.`#{name}`"
    end

    #
    # Return an array containing the fields part of the table primary key
    #
    # @return [Array] The primary key field names
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
      Table.exists?(connection, auditor.audit_db, name)
    end

    #
    # Copies the table structure from the audited schema to the audit one.
    #
    def copy_structure
      logger.info "Copying structure for table #{name} from watched to audit database"
      connection.query("CREATE TABLE #{audit} LIKE #{watched}")
      add_copied_at_field
      add_has_delta_field
    end

    # 
    # Checks the audit table structure for structure differences with the audited table. 
    # If the structures are different an exception is raised.
    # 
    def check_for_structure_changes!
      watched_fields = connection.query("DESC #{watched}").to_a
      audit_fields   = connection.query("DESC #{audit}").to_a
      delta = watched_fields - audit_fields
      delta = [delta, (audit_fields - watched_fields).reject { |i| METADATA_FIELDS.include?(i['Field']) }].flatten
      metadata_present = METADATA_FIELDS.all? { |f| (audit_fields - watched_fields).map { |i| i['Field'] }.include?(f) }

      if !delta.empty?
        raise "Structure has changed for table '#{name}'!"
      elsif !metadata_present
        raise "Missing meta-data fields in audit table '#{name}'!"
      else
        logger.info "Audit table #{name} is up to date."
      end
    end

    # 
    # Adds a +copied_at TIMESTAMP NULL+ field to the audit table
    #
    def add_copied_at_field
      logger.info "Adding #{name}.copied_at audit field..."
      connection.query("ALTER TABLE #{audit} ADD `_copied_at` TIMESTAMP NULL")
    end

    #
    # Adds a +has_delta TINYINT NOT NULL DEFAULT 0+ field to the audit table
    #
    def add_has_delta_field
      logger.info "Adding #{name}.has_delta audit field..."
      connection.query("ALTER TABLE #{audit} ADD `_has_delta` TINYINT NOT NULL DEFAULT 0")
    end

    #
    # Timestamp rows after they have been copied by updating the +copied_at+ field in the
    # audit table with the current timestamp.
    #
    def stamp_new_rows
      connection.query("UPDATE #{audit} SET `_copied_at` = NOW() WHERE `_copied_at` IS NULL")
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
          SELECT #{watched}.*, NULL, 0
          FROM #{watched} LEFT JOIN #{audit} ON #{pkey_equality_condition}
          WHERE #{audit}.`_copied_at` IS NULL
          EOF

          connection.query(q)
          cnt = connection.query("SELECT COUNT(*) FROM #{audit} WHERE `_copied_at` IS NULL").to_a[0].flatten.to_a[1]
          logger.info "Copied #{cnt} new rows for table #{name}."
          cnt
    end

    #
    # Flags the rows that are different in the audited and audit DBs, the rows are flagged
    #   so that the constraints defined to be checked on updates are properly enforced
    #
    def flag_row_deltas
      logger.debug "Flagging row deltas for #{name}"

      q = "SELECT #{pkey_selection(audit)} FROM #{audit} INNER JOIN #{watched} ON #{pkey_equality_condition} WHERE #{differences_filter}"
      r = connection.query(q).to_a

      unless r.count.zero?
        q = "UPDATE #{audit} SET `_has_delta` = 1 WHERE #{condition_from_hashes(r, audit)}"
        connection.query(q) 

        logger.warn "Flagged #{r.count} rows for check in #{name}" 
      end
    end

    #
    # Resets the delta flag, at the end of each auditing loop
    #
    def unflag_row_deltas
      logger.debug "Resetting row delta flags for #{name}"
      q = "UPDATE #{audit} SET `_has_delta` = 0"
      connection.query(q)
    end

    #
    # Enforces all the defined rules and constraints on the rows flagged
    #   as having deltas when compared to the original rows.  Each constraint 
    #   violation gets logged in order to be reported upon.
    #
    def check_rules_on_update

      # TODO : If has_delta is always checked rows will start accumulating and it'll all slow down

      logger.debug "Running UPDATE checks for #{name}"

      connection.query("SELECT * FROM #{audit} WHERE `_has_delta` = 1").each do |audit_row|

        pkey = audit_row.select { |k,v| primary_key.include?(k) }

        watched_row_query = "SELECT * FROM #{watched} WHERE #{condition_from_hashes(pkey)}"
        watched_row = connection.query(watched_row_query).first

        # If we do not have a matched row here it'll show in the deletion checks, so we
        # do nothing specific here
        if watched_row
          fields.each do |f|
            logger.debug "Executing INSERT audit rules for field '#{f.name}'"
            violations = f.on_update(watched_row, audit_row)
            violations.compact.each { |v| record_violation(v[:description], [audit_row, watched_row], v[:rule_name]) }
          end

          rules[:update].each do |rule|
            v = rule.execute(watched_row, audit_row)
            record_violation(v, [watched_row, audit_row], rule.name) if v
          end
        end
      end
    end

    #
    # Enforces all the defined rules and constraints on the new rows
    #   Each constraint violation gets logged in order to be reported upon.
    #
    def check_rules_on_insert
      logger.debug "Running INSERT checks for #{name}"

      connection.query("SELECT * FROM #{audit} WHERE `_copied_at` IS NULL").each do |audit_row|
        fields.each do |f|
          logger.debug "Executing INSERT audit rules for field '#{f.name}'"
          violations = f.on_insert(audit_row)
          violations.compact.each { |v| record_violation(v[:description], v[:item], v[:rule_name]) }
        end

        rules[:insert].each do |rule|
          v = rule.execute(audit_row)
          record_violation(v, audit_row, rule.name) if v
        end
      end
    end

    #
    # Records rule violations in a dedicated table
    #
    # @param v [Array<Hash>] The rule violations as returned by a rule execution
    #
    def record_violation(v, item, rule_name)
      stamp = Time.now.to_i
      serialized = [item].flatten.map { |i| i.inject({}) { |memo, obj| memo[obj[0].to_s] = obj[1].to_s; memo } }.inspect
      violation = "#{serialized}-#{name}-#{v}"
      fingerprint = Digest::SHA2.hexdigest(violation)

      already_exists = connection.query("SELECT COUNT(*) AS CNT FROM `#{auditor.audit_db}`.`_rule_violations` WHERE `fingerprint` = '#{fingerprint}'").to_a[0]['CNT'] > 0

      q = <<-EOF
        INSERT INTO `#{auditor.audit_db}`.`_rule_violations` (`fingerprint`, `audited_table`, `name`, `stamp`, `description`, `item`)
        VALUES ('#{fingerprint}', '#{name}', '#{rule_name || ''}', #{stamp}, '#{connection.escape(v)}', '#{connection.escape(item.inspect)}')
      EOF

      connection.query(q) unless already_exists
    end

    #
    # Return the table's fields
    #
    # @return [Array] An array of the table's fields
    #
    def fields(db = :watched)
      @fields ||= connection.query("DESC #{send(db)}").map do |f|
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
      conditions = fields.map do |field|
        "(#{field.difference_filter})"
      end

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
    def condition_from_hashes(p, table = nil)
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
    # Escapes +String+ values with simple quotes
    #
    # @param o [Object] An object which may require its string representation to be escaped for SQL
    # @return [String] The escaped string representation of the object
    #
    def escaped_value(o)
      (o.is_a?(String) || o.is_a?(Time)) ? "'#{o}'" : o.to_s
    end

    #
    # Tests whether the table exists in the given schema
    #
    # @param connection [Mysql2::Client] The database connection to use
    # @param schema [String] The schema in which the table existence should be checked
    # @param table [String] The table name whose existence should be checked
    # @return [Boolean] Whether the audit table exists
    #
    def self.exists?(connection, schema, table)
      connection.query("SHOW TABLES FROM `#{schema}`").to_a.map { |i| i.to_a.flatten[1] }.include?(table)
    end

  end
end
