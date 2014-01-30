require 'watchy/violation'
require 'watchy/logger_helper'

module Watchy

  #
  # Represents a message going through the queue
  #
  class Message

    include Watchy::LoggerHelper

    # The message body
    attr_accessor :body

    def initialize(body)
      @body = body.to_s.lines.select { |l| !l.strip.empty? }.map(&:chomp).join
    end

    #
    # Creates and handles a message from its text body
    #
    # @param msg [String] The message to handle
    #
    def self.handle(msg)
      new(msg).handle
    end

    #
    # Handles the message
    #
    def handle
      begin
        chunks = body.split('|')
        case chunks[0]

        when 'SIGNOFF' then Watchy::Violation.signoff(chunks[1].split(','))
        when 'REPORT'  then eval(chunks[1]).new.broadcast!
        when 'EVAL'    then eval(chunks[1])

        else logger.error "Invalid command received #{body}"
        end
      rescue
        logger.error "An error was raised when handling the following command : #{body}\n#{$!.message}\n#{$!.backtrace.join("\n")}"
      end
    end
  end
end
