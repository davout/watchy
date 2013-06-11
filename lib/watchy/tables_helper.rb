module Watchy
  module TablesHelper

    def bootstrap_audit_tables!
      audit_db_tables = connection.query("SHOW TABLES FROM `#{watched_db}`").to_a.map { |i| i.to_a.flatten[1] }

      audit_db_tables.each do |t| 
        table = Table.new(self, t)
        if table.exists?
          table.check_for_structure_changes!
        else
          table.copy_structure
        end
      end
    end
  end
end

