require 'mysql2'
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
    # @param db [Hash] The parameters passed to the +Mysql2::Client.new+ call
    #
    def self.connect_db(db_config)
      logger.info "Connecting to #{db_config[:username]}@#{db_config[:hostname]}:#{db_config[:port]}..."
      Mysql2::Client.new(db_config)
    end

    def db
      DatabaseHelper.db
    end

    def self.db
      @@db ||= connect_db(Settings[:database])
    end

    def audit_db
      @audit_db ||= Settings[:database][:audit_schema]
    end

    def watched_db
      @watched_db ||= Settings[:database][:schema]
    end
  end
end

