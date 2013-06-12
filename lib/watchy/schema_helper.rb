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
          create_schema!(audit_db)
        end
      else
        create_schema!(audit_db)
      end
    end

    def schema_exists?(schema) 
      connection.query('SHOW DATABASES').any? { |d| d['Database'] == schema }
    end

    def create_schema!(schema)
      connection.query("CREATE DATABASE `#{schema}`")
    end

  end
end
