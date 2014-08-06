require 'watchy/logger_helper'

module Watchy

  #
  # Base class for the audit rules definition
  #
  class Rule

    include Watchy::LoggerHelper

    #
    # The rule code
    #
    attr_accessor :rule_code

    #
    # The rule's optional name
    #
    attr_accessor :name

    def initialize(name = nil, &block)
      self.name       = name || "rule_#{(rand * 10 ** 6).to_i}"
      self.rule_code  = block
    end

    #
    # Reports on rule execution failures
    #
    def with_reporting(&block)
      begin
        block.call
      rescue
        logger.error("Exception <#{$!.message}> raised in rule <#{name}>\nTarget: <#{target.class.to_s}> : <#{target.name}>\n#{$!.backtrace.join("\n")}")
        raise
      end
    end

  end
end
