require 'mysql2'

module Watchy

  #
  # Wraps the MySQL client to provide better exception logging
  #
  class Mysql2Wrapper < Mysql2::Client

    include Watchy::LoggerHelper

    DEBUG_SQL = true

    #
    # Returns the full query in exception messages, optionnally outputs it
    #
    def query(q)
      begin
        DEBUG_SQL && logger.debug(q)
        super(q)
      rescue
        raise "MySQL query error, query was :\n#{q}\nOriginal message: #{$!.message}"
      end
    end

  end
end


