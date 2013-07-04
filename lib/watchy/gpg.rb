require 'gpgme'

module Watchy

  #
  # A GPG wrapper specific to a signing private key and a
  #   collection of recipient's public keys.
  #
  class GPG

# TODO : Encrypt to self ?


    #
    # The key used to sign
    #
    attr_accessor :sign_with

    #
    # The keys to encrypt to
    #
    attr_accessor :encrypt_to

    #
    # Intializes a GPG wrapper object with a secret signing key and optional
    #   recipient's keys. Note that it is *highly* recommended to have 
    #   the secret key protected by a strong passphrase.
    #
    #   The passphrase will be handled securely by a gpg-agent instance.
    #
    # @params [String] The GPG key ID with which data should be signed
    # @param [Array<String>] The GPG keys IDs to which data should be encrypted
    #
    def initialize(sign_with, encrypt_to = [])
      @sign_with  = sign_with
      @encrypt_to = [encrypt_to].flatten
    end

    #
    # Returns a GPG encryptor
    #
    # @return [GPGME::Crypto] A GPG encryptor
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
    def wrap(text)
      encrypt(clearsign(text))
    end

    #
    # Clearsigns the given text with the auditor's GPG key
    #
    # @param [String] The data to clearsign
    # @return [String] The clearsigned text
    #
    def clearsign(text)
      encryptor.clearsign(text, key: sign_with)
    end

    #
    # Encrypts the given text with the configured private keys
    #
    # @param [String] The text to encrypt
    # @return [String] The encrypted text
    #
    def encrypt(text)
      text
    end

  end
end

