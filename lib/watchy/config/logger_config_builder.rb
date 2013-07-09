module Watchy
  module Config
    class LoggerConfigBuilder

      def initialize
        @config = {}
      end

      def logger(l)
        @config[:logger] = l
      end

      def level(l)
        @config[:level] = l
      end

      def build
        { logging: @config }
      end

    end
  end
end

