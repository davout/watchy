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

    #
    # Calls the +rule_code+ proc
    #
    def execute(row, target)
      with_reporting(row, target) do
        target.instance_exec(row, &rule_code)
      end
    end

  end
end
