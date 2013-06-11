require 'logger'

module Watchy
  class Config

    @config = {}

    def initialize

      @defaults = {
        logger:     Logger.new(STDOUT),
        loglevel:   'debug',

        adapter:    'mysql2',

        watched_db: 'watchy',

        db_server: {
          username: 'watchy',
          password: 'watchy',
          host:     'localhost',
          port:     3306
        },

        audit_db: 'watchy_audit',

        watched_tables: {
          ledger: nil,
          users:  nil
        },

        consistency_checks: [],

        alerts: [],

        reports: [],

        gpg_identity: '',
        gpg_passphrase: '',

        gpg_recipient_identities: []
      }

      @config = @defaults
    end

    def [](k)
      @config[k]
    end
  end
end
