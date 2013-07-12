module Watchy

  #
  # Base clas for the audit rules definition
  #
  class Rule

    #
    # The rule code
    #
    attr_accessor :rule_code

    #
    # Records rule violations in a dedicated table
    #
    # @param v [Array<Hash>] The rule violations as returned by a rule execution
    #
    def record_violations(v)
      raise 'Implement me'
    end
  end
end
