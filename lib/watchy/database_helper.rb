require 'watchy/mysql2_wrapper'
require 'watchy/logger_helper'

module Watchy

  #
  # Implements methods related to the database connection
  #
  module DatabaseHelper

    class << self
      include LoggerHelper
    end

    #
    # Connects to the supplied +db+
    #
    # @param db_config [Hash] The parameters passed to the +Mysql2::Client.new+ call
    #
    def self.connect_db(db_config)
      logger.info "Connecting to #{db_config[:username]}@#{db_config[:hostname]}:#{db_config[:port]}..."
      Mysql2Wrapper.new({ reconnect: true }.merge(db_config))
    end

    #
    # Returns a connection to the configured DB, note that no schema is selected,
    #   queries must use fully qualified identifiers or issue a 'USE <schema>' statement
    #
    # @return [Mysql2::Client] The database connection
    #
    def db
      DatabaseHelper.db
    end

    #
    # Instantiates the DB client and keeps a single instance of it
    #
    # @return [Mysql2::Client] The database connection
    #
    def self.db
      @@db ||= connect_db(Settings[:database])
    end

    #
    # Returns the unquoted name of the audit schema
    #
    # @return [String] The name of the configured audit schema
    #
    def audit_db
      @audit_db ||= Settings[:database][:audit_schema]
    end

    #
    # Returns the unquoted name of the watched schema
    #
    # @return [String] The name of the configured watched schema
    #
    def watched_db
      @watched_db ||= Settings[:database][:schema]
    end

    #
    # Takes a snapshot of the audit DB, watched DB or both
    #
    # @param db [Symbol] The database for which a snapshot should be made
    # @param dir [String] The directory in which the snapshot should be saved
    # @param filename [String] The file name to use
    #
    def take_snapshot(db = :watched, dir = Dir.pwd, filename = nil)
      db_name = send("#{db}_db").to_s
      filename ||= "#{Time.now.strftime("%Y-%m-%d_%H%M%S")}_#{db_name}.sql.bz2"
      snapshot_command "mysqldump -u #{Settings[:database][:username]} -p#{Settings[:database][:password]} --databases #{db_name} | bzip2"
# | gpg #{}  #{File.join(dir, filename)}")

gpg = Settings[:gpg]


    end

  end
end

