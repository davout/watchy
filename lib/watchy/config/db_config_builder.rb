module Watchy
  module Config
    class DbConfigBuilder

      def initialize
        @config = {}
      end

      def username(u)
        @config[:username] = u
      end

      def password(p)
        @config[:password] = p
      end

      def hostname(h)
        @config[:hostname] = h
      end

      def port(p)
        @config[:port] = p
      end

      def schema(s)
        @config[:schema] = s
      end

      def audit_schema(as)
        @config[:audit_schema] = as
      end

      def drop_audit_schema!
        @config[:drop_audit_schema] = true
      end

      def build
        { database: @config }
      end

    end
  end
end

