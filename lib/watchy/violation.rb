require 'watchy/table'

module Watchy

  #
  # Represents a rule violation
  #
  class Violation

    class << self
      include Watchy::DatabaseHelper
    end

    #
    # Marks violation records as 'SIGNED_OFF' in order to indicate that
    #   the records have been taken into account and acted upon
    #
    # @param fingerprints [Array<String>] The collection of violation fingerprints
    #   to sign-off
    #
    def self.signoff(fingerprints = [])
      fps = fingerprints.select { |f| f.match(/\A[a-z0-9]{64}\Z/) }

      violations = db.query("SELECT * FROM `#{audit_db}`.`_rule_violations` WHERE state = 'PENDING' AND fingerprint IN (#{fingerprints.map { |f| "'#{f}'" }.join(', ')})").to_a

      violations.each do |vltn|
        # Sign-off on the violation itself
        db.query("UPDATE `#{audit_db}`.`_rule_violations` SET state = 'SIGNED-OFF' WHERE fingerprint = '#{vltn['fingerprint']}'")

        # Mark the relevant row as clean if and only if there aren't any other
        # pending violations for it
        other = db.query(<<-EOS)
          SELECT * 
          FROM `#{audit_db}`.`_rule_violations` 
          WHERE 
            `audited_table` = '#{vltn['audited_table']}' AND
            #{ vltn['field'] && "`field` = '#{vltn['field']}' AND " }
            `pkey` = '#{vltn['pkey']}' AND
            `state` = 'PENDING'
        EOS

        if other.to_a.length.zero?
          pkey = JSON.load(vltn['pkey'])
          db.query("UPDATE `#{audit_db}`.`#{vltn['table']}` SET `_has_violation` = 0 WHERE #{Table.condition_from_hashes(pkey)}")
        end
      end
    end
  end
end
