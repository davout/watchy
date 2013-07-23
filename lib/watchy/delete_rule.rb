require 'watchy/rule'

module Watchy

  #
  # Defines a rule that must be enforced at deletion time
  #
  class DeleteRule < Watchy::InsertRule
  end
end
