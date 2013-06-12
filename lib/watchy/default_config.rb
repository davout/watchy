require 'logger'
require 'configliere'

Settings({
  logger:     Logger.new(STDOUT),
  loglevel:   'info',

  sleep_for: 5,

  watched_db: 'watchy',
  audit_db: 'watchy_audit',

  db_server: {
    username: 'watchy',
    password: 'watchy',
    host:     'localhost',
    port:     3306
  },

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
})
