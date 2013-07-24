require 'watchy/queue'

module Watchy

  #
  # Implementation of an in-memory FIFO queue, used for development
  #
  class LocalQueue < Watchy::Queue

    def initialize
      @queue = []
    end

    #
    # Pushes a message in the +queue+ array
    #
    # @param msg [String] Message to push
    #
    def push_raw(msg)
      puts msg
      @queue << msg
    end

    #
    # Pops a message from the queue
    #
    # @return [String] The message or +nil+ if no message was present in the queue
    #
    def pop_raw
      @queue.shift
    end
  end
end
