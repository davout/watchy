require 'watchy/rule'

module Watchy

  #
  # Defines a rule that must be enforced at update time
  #
  class UpdateRule < Watchy::Rule

    def initialize(name = nil, &block)
      raise 'Must supply a block accepting two parameters' unless (block.arity == 2)
      super(name, &block)
    end

    #
    # Calls the +rule_code+ proc
    #
    def execute(original_row, updated_row, target)
      with_reporting do
        target.instance_exec(original_row, updated_row, &rule_code)
      end
    end

  end
end
