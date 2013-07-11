require 'docile'
require 'watchy/config/builder'

module Watchy

  #
  # Wraps all configuration related concerns with the exception
  #   of the configuration handled by the configliere gem
  #
  module Config

    #
    # Wraps the docile DSL helper gem
    #
    module DSL

      #
      # Returns the configuration hash given a builder and a configuration block
      #
      # @param blk [Proc] A user-provided configuration block 
      # @return [Hash] The configuration hash
      #
      def self.get_from(&blk)
        Docile.dsl_eval(Watchy::Config::Builder.new, &blk).resolve
      end

    end
  end
end
