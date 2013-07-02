require 'mustache'

module Watchy

  #
  # Defines the base class for user-defined reports
  #
  class Report < Mustache

    #
    # Initializes a report given a template
    #
    def initialize(auditor, template = nil)
      self.template_file = template
      self.auditor = auditor
    end

    #
    # Generates the report
    # 
    def generate
      auditor.gpg.wrap(render)
    end

  end
end

