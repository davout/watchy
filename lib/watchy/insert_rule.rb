require 'watchy/rule'

module Watchy

  #
  # Defines a rule that must be enforced at insertion time
  #
  class InsertRule < Watchy::Rule

    def initialize(name = nil, &block)
      raise 'Must supply a block accepting a single parameter' unless (block.arity == 1)
      super(name, &block)
    end

    def execute(row)
      rule_code.call(row)
    end

  end
end
