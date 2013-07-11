module Watchy
  module Config

    # 
    # Handles the logging related configuration hash
    #
    class LoggerConfigBuilder

      def initialize
        @config = {}
      end

      #
      # Defines the logger to use
      #
      # @param l [Logger] The logger instance to use
      #
      def logger(l)
        @config[:logger] = l
      end

      #
      # Defines the log level
      #
      # @param l [Symbol] The log level to use
      #
      def level(l)
        @config[:level] = l
      end

      #
      # Builds the defined configuration as a hash
      #
      # @return [Hash] The configuration hash
      #
      def build
        { logging: @config }
      end

    end
  end
end

