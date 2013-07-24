module Watchy

  #
  # Implements methods useful for dealing with database schemas and audit schema bootstrap
  #
  module SchemaHelper

    include Watchy::DatabaseHelper
    include Watchy::LoggerHelper

    #
    # Bootsraps an audit database according to the defined +Settings+, drops the existing audit database if requested
    #
    def bootstrap_databases!
      # Check for audited schema
      unless schema_exists?(watched_db)
        raise "Audited DB '#{watched_db}' does not exist." 
      end

      # Check for audit schema
      if schema_exists?(audit_db)
        if config[:database][:drop_audit_schema]
          logger.warn "Dropping already existing audit database ..."
          db.query("DROP DATABASE `#{audit_db}`")
          create_schema!(audit_db)
        end
      else
        create_schema!(audit_db)
      end
    end

    #
    # Checks whether a schema exists in the currently connected database
    # 
    # @param schema [String] The schema whose existence should be checked
    # @return [Boolean] Whether the schema exists in the currently connected database
    #
    def schema_exists?(schema) 
      db.query('SHOW DATABASES').any? { |d| d['Database'] == schema }
    end

    #
    # Creates a schema on the currently connected database
    #
    # @param schema [String] The schema that should be created
    #
    # This method does *not* check whether the schema exists before attempting to create it.
    #
    def create_schema!(schema)
      raise "Schema '#{schema}' already exists!" if schema_exists?(schema)
      db.query("CREATE DATABASE `#{schema}`")
    end

  end
end
