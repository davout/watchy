require 'logger'

module Watchy
  class Config

    @config = {}

    def initialize

      @defaults = {
        logger:   Logger.new(STDOUT),
        loglevel: 'debug',

        watched_db: {
          schema:   'watchy',
          username: 'watchy',
          password: 'watchy',
          host:     'localhost',
          port:     3306
        },

        audit_db: {
          schema:   'audit',
          username: 'watchy',
          password: 'watchy',
          host:     'localhost',
          port:     3306
        },

        watched_tables: {
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
