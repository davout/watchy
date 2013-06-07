require 'logger'
require 'watchy/version'
require 'watchy/config'
require 'watchy/auditor'

module Watchy
  def self.boot!(config)
      Watchy::Auditor.new(config).run!
  end
end

