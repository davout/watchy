require 'aws-sdk'

module Watchy

  #
  # Implements the +pop_raw+ and +push_raw+ methods for
  # the Amazon Simple Queue Service 
  #
  class AmazonSQS < Watchy::Queue

    def initialize(access_key_id, secret_access_key, queue_url, sqs_endpoint = 'sqs.eu-west-1.amazonaws.com')
      @client = AWS::SQS.new({
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
	sqs_endpoint: sqs_endpoint
      }).queues[queue_url]

      raise ("Unable to connect to the Amazon SQS queue") unless @client

      super()
    end

    #
    # Pushes a raw message to the queue
    #
    # @param msg [Watchy::Message] The message to push to the queue
    #
    def push_raw(msg)
      @client.send_message(msg)
    end

    #
    # Pops a single raw message from the queue
    #
    def pop_raw
      msg = nil 
      @client.receive_messages({ limit: 1 }) { |m| msg = m.body }
      msg
    end

  end
end
