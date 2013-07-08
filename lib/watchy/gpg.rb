require 'gpgme'

module Watchy

  #
  # A GPG wrapper specific to a signing private key and a
  #   collection of recipient's public keys.
  #
  class GPG

    #
    # The default options
    #
    DEFAULT_OPTIONS = {
      clearsign: false
    }

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
    def initialize(sign_with_p, encrypt_to = [], options = {})
      @options = DEFAULT_OPTIONS.merge(options) 
      @sign_with  = GPGME::Key.find(:secret, sign_with_p)
      @encrypt_to = [encrypt_to].map { |k| GPGME::Key.find(:public, k) }.flatten
    end

    #
    # Returns a GPG encryptor
    #
    # @return [GPGME::Crypto] A GPG encryptor
    #
    def encryptor
      @encryptor ||= GPGME::Crypto.new(armor: true)
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
      if @options[:clearsign]
        encrypt(clearsign(text))
      else
        encrypt(text, sign: true)
      end
    end

    #
    # Clearsigns the given text with the auditor's GPG key
    #
    # @param [String] The data to clearsign
    # @return [String] The clearsigned text
    #
    def clearsign(text)
      encryptor.clearsign(text, signer: sign_with)
    end

    #
    # Encrypts the given text with the configured private keys
    #
    # @param [String] The text to encrypt
    # @return [String] The encrypted text
    #
    def encrypt(text, opts = {})
      if opts[:sign]
        sign = true
        signers = [sign_with]
      end 

      if encrypt_to.empty?
        puts 'Not encrypting'
        text
      else
        encryptor.encrypt(text, recipients: encrypt_to, always_trust: true, sign: sign, signers: signers || [])
      end
    end

  end
end

