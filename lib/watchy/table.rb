module Watchy
  class Table

    attr_accessor :name, :columns, :auditor, :connection, :logger

    def initialize(auditor, name)
      @connection = auditor.connection
      @logger = auditor.logger
      @auditor = auditor
      @name = name
    end

    def watched
      identifier(auditor.watched_db) 
    end

    def audit
      identifier(auditor.audit_db)
    end

    def identifier(db)
      "`#{db}`.`#{name}`"
    end

    def primary_key
      'id'
    end

    def exists?
      connection.query("SHOW TABLES FROM #{auditor.audit_db}").to_a.map { |i| i.to_a.flatten[1] }.include?(name)
    end

    def copy_structure
      logger.info "Copying structure for table #{name} from watched to audit database"
      connection.query("CREATE TABLE #{audit} LIKE #{watched}")
      add_copied_at_field
    end

    def check_for_structure_changes!
      watched_fields = connection.query("DESC #{watched}").to_a
      audit_fields   = connection.query("DESC #{audit}").to_a
      delta = watched_fields - audit_fields
      delta = [delta, (audit_fields - watched_fields).reject { |i| i['Field'] == 'copied_at' }  ].flatten

      if delta.empty?
        logger.info "Audit table #{name} is up to date."
      else
        raise "Unable to continue, structure of audited and audit tables are different for table #{name}"
      end
    end

    def add_copied_at_field
      logger.info "Adding #{name}.copied_at audit field..."
      connection.query("ALTER TABLE #{audit} ADD `copied_at` TIMESTAMP NULL")
    end

    def stamp_new_rows
      connection.query("UPDATE #{audit} SET `copied_at` = NOW() WHERE `copied_at` IS NULL")
    end

    def copy_new_rows
      logger.debug "Copying new rows into #{name} ..."

      pkey_equality_condition = "(#{[primary_key].flatten.map { |k| "#{watched}.`#{k}` = #{audit}.`#{k}`" }.join(' AND ')})"

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
  end
end
