module Watchy

  #
  # Base class for the audit rules definition
  #
  class Rule

    #
    # The rule code
    #
    attr_accessor :rule_code

    #
    # The rule's optional name
    #
    attr_accessor :name

    def initialize(name = nil, &block)
      self.name = name || "rule_#{(rand * 10 ** 6).to_i}"
      self.rule_code = block
    end
  end
end
