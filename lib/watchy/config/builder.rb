require 'docile'

require 'watchy/config/db_config_builder'
require 'watchy/config/gpg_config_builder'
require 'watchy/config/audit_config_builder'
require 'watchy/config/logger_config_builder'
require 'watchy/config/reporting_config_builder'

module Watchy
  module Config

    #
    # Builds a configuration hash using the block passed to the +Watchy.configure+ call
    #
    class Builder

      #
      # Initializes the configuration builder with an empty config array
      # 
      def initialize
        @config = []
      end

      #
      # Sets the interval to sleep for, defaults to 1s
      #
      # @param s [Fixnum] The number of seconds to sleep between each audit loop
      #
      def sleep_for(s)
        @config << { sleep_for: s }
      end

      #
      # Sets the configuration for the audited database connection
      #
      def database(&block)
        @config << Docile.dsl_eval(DbConfigBuilder.new, &block).build
      end

      #
      # Sets the logger
      #
      def logging(&block)
        @config << Docile.dsl_eval(LoggerConfigBuilder.new, &block).build
      end

      #
      # Sets the GPG related configuration
      #
      def gpg(&block)
        @config << Docile.dsl_eval(GPGConfigBuilder.new, &block).build
      end

      #
      # Defines the exact auditing to be performed
      #
      def audit(&block)
        @config << Docile.dsl_eval(AuditConfigBuilder.new, &block).build
      end

      #
      # Defines the reporting to be performed
      #
      def reporting(&block)
        @config << Docile.dsl_eval(ReportingConfigBuilder.new, &block).build
      end

      #
      # Defines the queue to use for receiving messages
      #
      def receive_queue(q)
        @config << { receive_queue: q }
      end

      #
      # Defines the queue to use for broadcasting messages
      #
      # @param q [Watchy::Queue] An instance of a class extending +Watchy::Queue+
      #
      def broadcast_queue(q)
        @config << { broadcast_queue: q }
      end

      #
      # Returns the full configuration hash
      #
      # @return [Hash] The configuration hash
      #
      def resolve
        @config.inject({}) { |memo, h| memo.merge(h) }
      end

    end
  end
end

