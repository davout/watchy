require 'watchy/rule'

module Watchy

  #
  # Defines a rule that must be enforced at insertion time
  #
  class InsertRule < Watchy::Rule

    def initialize(&block)
      raise 'Must supply a block accepting a single parameter' unless (block.arity == 1)
      self.rule_code = block
    end

    def execute(row)
      r  = block.call(row)
      record_violations(r)
    end

  end
end
