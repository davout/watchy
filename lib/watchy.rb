require 'mysql2'

require 'watchy/version'
require 'watchy/default_config'
require 'watchy/auditor'

# 
# The Watchy module implements the +boot!+ method used to spawn a new +Watchy::Auditor+ instance
#
module Watchy

  #
  # Creates a new +Watchy::Auditor+ instance and calls the +Watchy::Auditor#run!+ method on it
  #
  def self.boot!
    Watchy::Auditor.new.run!
  end
end

