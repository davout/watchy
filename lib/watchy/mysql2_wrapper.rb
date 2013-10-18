require 'mysql2'

module Watchy

  #
  # Wraps the MySQL client to provide better exception logging
  #
  class Mysql2Wrapper < Mysql2::Client

    #
    # Returns the full query in exception messages
    #
    def query(q)
      begin
        super(q)
      rescue
        raise "MySQL query error, query was :\n#{q}\nOriginal message: #{$!.message}"
      end
    end

  end
end


