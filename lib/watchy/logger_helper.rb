module Watchy

  #
  # Implements a logger accessor
  #
  module LoggerHelper

    #
    # Instantiates a +Logger+ object according to the +Settings+ and memoizes it
    #
    # @return [Logger] The current logger
    #
    def logger
      unless @logger
        @logger = Settings[:logger] || Logger.new(STDOUT)
        @logger.level = eval("Logger::Severity::#{Settings[:loglevel].upcase}")
      end

      @logger
    end

  end
end
