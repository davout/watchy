module Watchy

  #
  # Implements a logger accessor
  #
  module LoggerHelper

    #
    # Instantiates a +Logger+ object according to the +configuration+ and memoizes it
    #
    # @return [Logger] The current logger
    #
    def self.logger
      @@logger ||= nil
      unless @@logger
        c = Settings[:logging] 
        @@logger = c[:logger]
        @@logger.level = eval("Logger::Severity::#{c[:level].upcase}")
      end

      @@logger
    end

    def logger
      LoggerHelper.logger
    end

  end
end
