module Watchy

  #
  # Provides binary data helpers
  #
  module BinHelpers

    # Converts a hexadecimal string to its binary representation
    def to_bin(s); s && s.scan(/../).map { |x| x.hex }.pack('c*'); end

    # Converts a binary string to its hex representation
    def to_hex(s); s && s.unpack('H*').first; end
  end
end

