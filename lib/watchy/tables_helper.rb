module Watchy

  #
  # Implements the bootstrapping of all the audit tables
  #
  module TablesHelper

    #
    # Returns the DDL for creating the metadata tables
    #
    # @return [String] Metadata SQL tables creation
    #
    def metadata_tables_ddl
      {
        '_rule_violations' => <<-EOS
          CREATE TABLE `#{audit_db}`.`_rule_violations` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `fingerprint` VARCHAR(64) NOT NULL,
            `audited_table` VARCHAR(255) NOT NULL,
            `field` VARCHAR(255) NULL,
            `name` VARCHAR(255) NOT NULL,
            `stamp` BIGINT NOT NULL,
            `description` VARCHAR(255) NOT NULL,
            `item` TEXT NOT NULL,
            `pkey` TEXT NULL,
            `row_version` BIGINT NOT NULL,
            `state` VARCHAR(10) NOT NULL DEFAULT 'pending',
            `signed_off_at` BIGINT NULL,
            PRIMARY KEY (`id`),
            UNIQUE INDEX `fingerprint_UNIQUE` (`fingerprint` ASC) )
        EOS
      }
    end
    
    #
    # Bootstrap all the audited tables copies in the audit database
    #
    def bootstrap_audit_tables!
      audited_tables = config[:audit][:tables].keys.map(&:to_s)

      audited_tables.each do |t| 
        table = Table.new(self, t, config[:audit][:tables][t.to_sym][:rules], config[:audit][:tables][t.to_sym][:auditing_enabled])

        if table.exists?
          table.check_for_structure_changes!
        else
          table.copy_structure
          table.create_versioning_table
        end
      end

      add_metadata_tables!
    end

    #
    # Adds the internal state tracking tables on the audit schema
    #
    def add_metadata_tables!
      metadata_tables_ddl.each do |table, ddl_script|
        if Table.exists?(connection, audit_db, table)
          logger.info "Table '#{table}' already exists."
        else
          logger.info "Creating table '#{table}' on the audit database"
          connection.query(ddl_script)
        end
      end
    end

    #
    # Returns the collection of audited tables
    #
    # @return [Array<Watchy::Table>] The collection of audited tables
    #
    def tables
      @tables ||= config[:audit][:tables].keys.map { |k| Table.new(self, k.to_s, config[:audit][:tables][k][:rules], config[:audit][:tables][k][:versioning_enabled]) }
    end

  end
end

