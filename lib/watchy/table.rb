require 'watchy/field'

module Watchy

  #
  # Represents an audited table
  #
  class Table

    attr_accessor :name, :columns, :auditor, :connection, :logger

    #
    # Initializes a table given an +auditor+ and a +name+
    #
    # @param auditor [Watchy::Auditor] The current +Watchy::Auditor+ instance
    # @param name [String] The table name in the audited schema
    #
    def initialize(auditor, name)
      @connection = auditor.connection
      @logger     = auditor.logger
      @auditor    = auditor
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
      connection.query("SHOW TABLES FROM `#{auditor.audit_db}`").to_a.map { |i| i.to_a.flatten[1] }.include?(name)
    end

    #
    # Copies the table structure from the audited schema to the audit one.
    #
    def copy_structure
      logger.info "Copying structure for table #{name} from watched to audit database"
      connection.query("CREATE TABLE #{audit} LIKE #{watched}")
      add_copied_at_field
    end

    # 
    # Checks the audit table structure for structure differences with the audited table. 
    # If the structures are different an exception is raised.
    # 
    def check_for_structure_changes!
      watched_fields = connection.query("DESC #{watched}").to_a
      audit_fields   = connection.query("DESC #{audit}").to_a
      delta = watched_fields - audit_fields
      delta = [delta, (audit_fields - watched_fields).reject { |i| i['Field'] == 'copied_at' }].flatten
      copied_at_field_present = (audit_fields - watched_fields).any? { |i| i['Field'] == 'copied_at' }

      if !delta.empty?
        raise "Structure has changed for table '#{name}'!"
      elsif !copied_at_field_present
        raise "Missing 'copied_at' field in audit table '#{name}'!"
      else
        logger.info "Audit table #{name} is up to date."
      end
    end

    # 
    # Adds a +copied_at TIMESTAMP NULL+ field to the audit table
    #
    def add_copied_at_field
      logger.info "Adding #{name}.copied_at audit field..."
      connection.query("ALTER TABLE #{audit} ADD `copied_at` TIMESTAMP NULL")
    end

    #
    # Timestamp rows after they have been copied by updating the +copied_at+ field in the
    # audit table with the current timestamp.
    #
    def stamp_new_rows
      connection.query("UPDATE #{audit} SET `copied_at` = NOW() WHERE `copied_at` IS NULL")
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
          SELECT *, NULL 
          FROM #{watched}
          WHERE NOT EXISTS (
            SELECT * FROM #{audit} WHERE #{pkey_equality_condition} 
          )
          EOF

          connection.query(q)
          cnt = connection.query("SELECT COUNT(*) FROM #{audit} WHERE `copied_at` IS NULL").to_a[0].flatten.to_a[1]
          logger.info "Copied #{cnt} new rows."
          cnt
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
          f['Key'],
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
      f = fields.map do |field|
        "(#{field.difference_filter})"
      end.join(' OR ')
    end

    #
    # Returns the primary key equality condition
    #
    # @return [String] A SQL fragment used as +INNER JOIN+ condition to join the watched and audited tables
    #
    def pkey_equality_condition
      "(#{[primary_key].flatten.map { |k| "#{watched}.`#{k}` = #{audit}.`#{k}`" }.join(' AND ')})"
    end
  end
end
