module Watchy
  module SchemaHelper

    def bootstrap_databases!
      # Check for audited schema
      unless schema_exists?(watched_db)
        raise "Audited DB #{watched_db} does not exist." 
      end

      # Check for audit schema
      if schema_exists?(audit_db)
        if Settings[:drop]
          logger.warn "Dropping already existing audit database ..."
          connection.query("DROP DATABASE `#{audit_db}`")
          create_db!(audit_db)
        end
      else
        create_db!(audit_db)
      end
    end

    def schema_exists?(db)
      connection.query('SHOW DATABASES').any? { |d| d['Database'] == db }
    end

    def create_db!(db)
      connection.query("CREATE DATABASE `#{db}`")
    end

  end
end
