require 'watchy/delete_rule'

module Watchy

  #
  # This rule is enforced by default on all tables, it enforces that
  #   no DELETE is ever made on them.
  #
  class DefaultDeleteRule < Watchy::DeleteRule
    def initialize
      rule = Proc.new { |a| "Row was deleted from the watched DB." }
      super(:default_delete_rule, &rule)
    end
  end
end

