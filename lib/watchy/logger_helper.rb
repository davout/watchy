module Watchy
  module LoggerHelper

    def logger
      unless @logger
        @logger = Settings[:logger] || Logger.new(STDOUT)
        @logger.level = eval("Logger::Severity::#{Settings[:loglevel].upcase}")
      end

      @logger
    end

  end
end
