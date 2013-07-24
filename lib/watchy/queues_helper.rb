module Watchy

  module QueuesHelper

    def broadcast_queue
      Settings[:broadcast_queue]
    end

    def receive_queue
      Settings[:receive_queue]
    end
  end
end

