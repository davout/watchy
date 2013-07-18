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
      # @param u [String] The username to use when connecting to the database
      #
      def username(u)
        @config[:username] = u
      end

      #
      # Sets the password
      #
      # @param p [String] The password to use when connecting to the database
      #
      def password(p)
        @config[:password] = p
      end

      # 
      # Sets the host to connect to
      #
      # @param h [String] The database server hostname
      #
      def hostname(h)
        @config[:hostname] = h
      end

      #
      # Sets the port used for connecting
      #
      # @param p [Fixnum] The port to use for connecting to the database
      #
      def port(p)
        @config[:port] = p
      end

      #
      # Defines the schema to audit
      # 
      # @param s [String] The schema to audit
      #
      def schema(s)
        @config[:schema] = s
      end

      #
      # Defines the schema to use as the audit metadata storage
      # 
      # @param as [String] The schema to use as meta-data and audit data storage
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
      # Builds the defined configuration as a hash
      #
      # @return [Hash] The configuration hash
      #
      def build
        @config[:connection] = Mysql2::Client.new(@config)
        { database: @config }
      end

    end
  end
end

