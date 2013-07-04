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
    def logger
      unless @logger
        @logger = configuration[:logger] || Logger.new(STDOUT)
        @logger.level = eval("Logger::Severity::#{configuration[:loglevel].upcase}")
      end

      @logger
    end

  end
end
