module Watchy
  module Config

    # 
    # Handles the GPG related configuration hash
    #
    class GPGConfigBuilder
      
      #
      # Defines the GPG key to use for signatures
      #
      # @param k [String] The GPG key identity, usually an e-mail address
      #
      def sign_with(k)
        @sign_with = k
      end

      #
      # Defines the keys to which messages should be encrypted,
      #   call it multiple times or pass it multiple arguments to 
      #   define multiple recipients
      #
      # @param k [String] A GPG key identity, usually an e-mail address
      #
      def encrypt_to(*k)
        @encrypt_to ||= []
        @encrypt_to << k
      end

      #
      # Builds the defined configuration as a hash
      #
      # @return [Hash] The configuration hash
      #
      def build
        { gpg:  Watchy::GPG.new(@sign_with, (@encrypt_to || []).flatten) }
      end

    end
  end
end

