module Watchy

  #
  # Implements the bootstrapping of all the audit tables
  #
  module TablesHelper

    #
    # Bootstrap all the audited tables copies in the audit database
    #
    def bootstrap_audit_tables!
      audited_tables = config[:audit][:tables].keys.map(&:to_s)

      audited_tables.each do |t| 
        table = Table.new(self, t)

        if table.exists?
          table.check_for_structure_changes!
        else
          table.copy_structure
        end
      end
    end

    #
    # Returns the collection of audited tables
    #
    # @return [Array<Watchy::Table>] The collection of audited tables
    #
    def tables
      @tables ||= config[:audit][:tables].keys.map { |k| Table.new(self, k.to_s) }
    end

  end
end

