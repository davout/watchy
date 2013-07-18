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
    # @param db [Mysql2::Client] The connection to issue queries against
    # @param gpg [Watchy::GPG] The GPG wrapper in charge of report signature and encryption
    # @param template_file [String] The path to the template file
    #
    def initialize(config, template_file = nil)
      @template_file  = template_file && File.expand_path(template_file)
      @db             = config[:database][:connection]
      @gpg            = config[:gpg]
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
