require 'gpgme'

module Watchy

  #
  # GPG signature and encryption methods
  #
  module GPG

    #
    # Returns the key to sign with
    #
    # @return [String] The GPG signature key to use for signing the
    #   generated reports.
    #
    def signature_key
      Settings[:gpg_signature_key]
    end

    #
    # Returns the keys to encrypt to
    #
    # @return [Array<String>] The GPG keys that should be able to 
    #   decrypt the generated reports
    #
    def encryption_keys
      [Settings[:gpg_encryption_keys]].flatten
    end

    #
    # Returns the GPG encryptor
    #
    # @return [GPGME::Crypto] The GPG encryptor
    #
    def encryptor
      @encryptor ||= GPGME::Crypto.new
    end

    #
    # Encrypts and signs the content passed as parameter with
    #   configured keys
    #
    # @param [String] The data to sign and encrypt
    # @return [String] The signed and encrypted data as 
    #   an ASCII-armored string
    # 
    def wrap

    end

  end
end

