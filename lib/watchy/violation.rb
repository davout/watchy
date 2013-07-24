module Watchy

  #
  # Represents a rule violation
  #
  class Violation

    class << self
      include Watchy::DatabaseHelper
    end

    def self.signoff(fingerprints = [])
      fps = fingerprints.select { |f| f.match(/\A[a-z0-9]{64}\Z/) }

      q = <<-EOS
        UPDATE `#{audit_db}`.`_rule_violations` 

        SET 
          `state` = 'SIGNED-OFF', 
          `signed_off_at` = #{Time.now.to_i}

        WHERE 
          `fingerprint` IN (#{fingerprints.map { |f| "'#{f}'" }.join(', ')})  AND 
          `state` = 'PENDING'
      EOS

      db.query(q)
    end
  end
end
