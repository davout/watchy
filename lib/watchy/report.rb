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
      @template_file  = template_file
      @db             = db
      @gpg            = gpg
    end

    #
    # Generates the report
    # 
    # @return [String] The generated report, signed and ecnrypted
    #
    def generate
      gpg.wrap(render)
    end

  end
end

