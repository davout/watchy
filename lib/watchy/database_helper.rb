require 'mysql2'

module Watchy

  #
  # Implements methods related to the database connection
  #
  module DatabaseHelper

    # 
    # Instantiates a connection according to the configuration and memoizes it.
    #
    # @return [Mysql2::Client] A database connection
    #
    def connection
      @connection ||= connect_db(config[:database])
    end

    #
    # Connects to the supplied +db+
    #
    # @param db [Hash] The parameters passed to the +Mysql2::Client.new+ call
    #
    def connect_db(db)
      logger.info "Connecting to #{db[:username]}@#{db[:hostname]}:#{db[:port]}..."
      Mysql2::Client.new(db)
    end

  end
end

