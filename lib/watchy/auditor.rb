
module Watchy
  class Auditor

    def initialize(config)
      @logger     = config[:logger]
      @watched_db = config[:watched_db]
                           
      l.warn "Booting Watchy #{Watchy::VERSION}"
    end

    def l
      @logger
    end

    def run!
      l.warn "Starting audit..."
    watched_db = con
      l.warn "Connecting to #{watched_db[:schema]} at #{watched_db[:host]} with #{watched_db[:username]}/*****" 

    end

    def method_missing(method, *args, &block)
      config.has_key?(args[0]) ? config[args[0]] : super
    end
  end
end

