module Watchy

  #
  # Represents a message going through the queue
  #
  class Message

    # The message body
    attr_accessor :body

    def initialize(body)
      @body = body
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
    end
  end
end
