module Watchy
  module Config

    # 
    # Handles the GPG related configuration hash
    #
    class GPGConfigBuilder

      def initialize
        @config = { encrypt_to: [] }
      end

      #
      # Defines the GPG key to use for signatures
      #
      # @param k [String] The GPG key identity, usually an e-mail address
      #
      def sign_with(k)
        @config[:sign_with] = k
      end

      #
      # Defines the keys to which messages should be encrypted,
      #   call it multiple times or pass it multiple arguments to 
      #   define multiple recipients
      #
      # @param k [String] A GPG key identity, usually an e-mail address
      #
      def encrypt_to(*k)
        @config[:encrypt_to] << k
      end

      #
      # Builds the defined configuration as a hash
      #
      # @return [Hash] The configuration hash
      #
      def build
        @config[:encrypt_to].flatten.uniq!
        { gpg: @config }
      end

    end
  end
end

