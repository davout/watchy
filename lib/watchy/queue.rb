module Watchy

  #
  # Implements a unified messaging interface, in production this'll usually be
  #   something like Amazon SQS.
  #
  # This class should be extended by all backends, extended classes should implement the
  #   +push_raw+ and +pop_raw+ methods. No assumption is made regarding the underlying 
  #   backend, it may be FIFO, LIFO or random.
  #
  class Queue

    # The GPG encryptor
    attr_accessor :gpg

    #
    # Signs encrypts and pushes a message down the queue
    #
    # @param msg [String] The message to push
    #
    def push(msg)
      push_raw(wrap(msg))
    end

    #
    # Pops a message from the queue, decrypts it and verifies its signatures
    #
    # @return [String] The message or +nil+ if the signature didn't verify
    #
    def pop
      popped = pop_raw
      unwrap(popped) if popped
    end

    #
    # Signs and encrypts the message
    #
    # @return [String] The signed and encrypted message
    #
    def wrap(msg)
      raise "Can't broadcast unencrypted messages" unless gpg.can_encrypt?
      gpg.wrap(msg)
    end

    #
    # Decrypts the message and checks its signature
    #
    # @return [String] The message if decryption and signature verification succeeded
    #
    def unwrap(raw)
      gpg.unwrap(raw)
    end

  end
end
