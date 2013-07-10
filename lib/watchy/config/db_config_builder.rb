module Watchy
  module Config

    # 
    # Handles the database related configuration hash
    #
    class DbConfigBuilder

      def initialize
        @config = {}
      end

      #
      # Sets the username to authenticate against the DB
      #
      def username(u)
        @config[:username] = u
      end

      #
      # Sets the password
      #
      def password(p)
        @config[:password] = p
      end

      # 
      # Sets the host to connect to
      #
      def hostname(h)
        @config[:hostname] = h
      end

      #
      # Sets the port used for connecting
      #
      def port(p)
        @config[:port] = p
      end

      #
      # Defines the schema to audit
      # 
      def schema(s)
        @config[:schema] = s
      end

      #
      # Defines the schema to use as the audit metadata storage
      # 
      def audit_schema(as)
        @config[:audit_schema] = as
      end

      #
      # If this flag is set to +true+ the existing audit schema will ve wiped before
      #   being re-created from scratch
      #   
      def drop_audit_schema!
        @config[:drop_audit_schema] = true
      end

      #
      # Builds the defined configuration as a has
      #
      def build
        { database: @config }
      end

    end
  end
end

