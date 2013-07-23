module Watchy
  module Config

    # 
    # Handles the GPG related configuration hash
    #
    class GPGConfigBuilder
      
      def initialize
        @verify_sigs_with = []
      end
      
    
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
      # Defines the public keys against which the signatures of signed data should
      #   be verified.
      #
      # @param keys [Array<String>] Key identifier or array of identifiers
      #
      def verify_sigs_with(keys)
        @verify_sigs_with << keys
      end

      #
      # Builds the defined configuration as a hash
      #
      # @return [Hash] The configuration hash
      #
      def build
        { gpg:  Watchy::GPG.new(@sign_with, (@encrypt_to || []).flatten, [@verify_sigs_with].flatten) }
      end

    end
  end
end

