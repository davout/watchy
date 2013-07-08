require 'mustache'

module Watchy

  #
  # Defines the base class for user-defined reports
  #
  class Report < Mustache

    # 
    # The GPG encryptor used to sign and encrypt the generated report
    #
    attr_accessor :gpg

    #
    # The database connection against which the report should run
    #
    attr_accessor :db

    #
    # Initializes a report
    #
    # @param [Mysql2::Client] The connection to issue queries against
    # @param [Watchy::GPG] The GPG wrapper in charge of report signature and encryption
    # @param [String] The path to the template file
    #
    def initialize(db, gpg, template_file = nil)
      @template_file  = template_file && File.expand_path(template_file)
      @db             = db
      @gpg            = gpg
    end

    #
    # Generates the report
    # 
    # @return [String] The generated report, signed and encrypted
    #
    def generate
      gpg.wrap(do_render)
    end

    # 
    # Renders the template using the +template+ instance method od
    #   the +@template_file+ file in this order.
    #
    # @return [String] The generated report
    #
    def do_render
      respond_to?(:template) ? render(template) : render
    end
  end
end
