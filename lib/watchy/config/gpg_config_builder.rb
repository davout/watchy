module Watchy
  module Config
    class GPGConfigBuilder

      def initialize
        @config = { encrypt_to: [] }
      end

      def sign_with(k)
        @config[:sign_with] = k
      end

      def encrypt_to(k)
        @config[:encrypt_to] << k
      end

      def build
        @config[:encrypt_to].uniq!
        { gpg: @config }
      end

    end
  end
end

