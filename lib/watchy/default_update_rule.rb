module Watchy

  #
  # This rule is enforced by default on all fields, it enforces that
  #   no UPDATE is ever made on them.
  #
  class DefaultUpdateRule < Watchy::UpdateRule
    def initialize(field)
      rule = Proc.new { |w,a| "Field #{field} is different (#{w[field]} -- #{a[field]})" unless w[field] == a[field] }
      super(:default_update_rule, &rule)
    end
  end
end

