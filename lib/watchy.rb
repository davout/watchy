require 'watchy/version'
require 'watchy/config/defaults'
require 'watchy/config/dsl'
require 'watchy/auditor'

# 
# The Watchy module implements the +boot!+ method used to spawn a new +Watchy::Auditor+ instance
#
module Watchy

  #
  # Creates a new +Watchy::Auditor+ instance and calls the +Watchy::Auditor#run!+ method on it
  #
  def self.boot!
    @@config ||= {}
    Settings(@@config)
    Watchy::Auditor.new(Settings).run!
  end

  #
  # Sets the configuration of the instance using a cute little DSL
  #
  def self.configure(&block)
    @@config = Watchy::Config::DSL.get_from(&block)
  end

end

