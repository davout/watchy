module Watchy

  #
  # This module contains accessors to the two queues used
  #   by Watchy
  #
  module QueuesHelper

    #
    # Returns the broadcast queue used to broadcast messages such
    #   as generated reports
    #
    # @return [Watchy::Queue] The broadcast queue
    #
    def broadcast_queue
      Settings[:broadcast_queue]
    end

    #
    # Returns the receive queue used to receive messages containing
    #   commands for the auditor
    #
    # @return [Watchy::Queue] The receive queue
    #
    def receive_queue
      Settings[:receive_queue]
    end
  end
end

