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
        c = config[:logging]

        @logger = c[:logger]
        @logger.level = eval("Logger::Severity::#{c[:level].upcase}")
      end

      @logger
    end

  end
end
