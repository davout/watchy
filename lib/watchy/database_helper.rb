module Watchy
  module DatabaseHelper

    def connection
      @connection ||= connect_db(Settings[:db_server])
    end

    def connect_db(db)
      logger.info "Connecting to #{db[:username]}@#{db[:host]}:#{db[:port]}..."
      Mysql2::Client.new(db)
    end

  end
end

