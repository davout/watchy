require 'watchy/rule'

module Watchy

  #
  # Defines a rule that must be enforced at update time
  #
  class UpdateRule < Watchy::Rule

    def initialize(&block)
      raise 'Must supply a block accepting two parameters' unless (block.arity == 2)
      self.rule_code = block
    end

    def execute(original_row, updated_row)
      r  = block.call(original_row, updated_row)
      record_violations(r)
    end

  end
end
