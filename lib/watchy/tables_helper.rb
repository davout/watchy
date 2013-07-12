module Watchy

  #
  # Implements the bootstrapping of all the audit tables
  #
  module TablesHelper

    METADATA_TABLES = {
      :_rule_violations => <<-EOS
          CREATE TABLE `#{audit_db}`.`_rule_violations` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `fingerprint` VARCHAR(64) NOT NULL,
            `audited_table` VARCHAR(255) NOT NULL,
            `name` VARCHAR(255) NULL,
            `stamp` TIMESTAMP NOT NULL,
            `description` VARCHAR(255) NOT NULL,
            `item` TEXT NULL,
            PRIMARY KEY (`id`),
            UNIQUE INDEX `fingerprint_UNIQUE` (`fingerprint` ASC) )
      EOS
    }

    #
    # Bootstrap all the audited tables copies in the audit database
    #
    def bootstrap_audit_tables!
      audited_tables = config[:audit][:tables].keys.map(&:to_s)

      audited_tables.each do |t| 
        table = Table.new(self, t, config[:audit][:tables][t.to_sym][:rules])

        if table.exists?
          table.check_for_structure_changes!
        else
          table.copy_structure
        end
      end

      add_metadata_tables!
    end

    def add_metadata_tables!
      METADATA_TABLES.each do |table, ddl_script|
        if connection.query("SHOW TABLES FROM `#{audit_db}`").to_a.map { |i| i.to_a.flatten[1] }.include?(table.to_s)
          logger.info "Table #{table} already exists."
        else
          logger.info "Creating table #{table} on the audit database"
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
      @tables ||= config[:audit][:tables].keys.map { |k| Table.new(self, k.to_s, config[:audit][:tables][k][:rules]) }
    end

  end
end

