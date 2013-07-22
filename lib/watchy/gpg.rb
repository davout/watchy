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
    # @param sign_with [String] The GPG key ID with which data should be signed
    # @param encrypt_to [Array<String>] The GPG keys IDs to which data should be encrypted
    #
    def initialize(sign_with, encrypt_to = [], verify_sigs_with = [], options = {})
      @options          = DEFAULT_OPTIONS.merge(options) 
      @sign_with        = GPGME::Key.find(:secret, sign_with)
      @encrypt_to       = [encrypt_to].flatten.map { |k| GPGME::Key.find(:public, k) }.flatten
      @verify_sigs_with = [verify_sigs_with].flatten.map { |k| GPGME::Key.find(:public, k) }.flatten 
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
    # @param text [String] The data to sign and encrypt
    # @return [String] The signed and encrypted data as 
    #   an ASCII-armored string
    # 
    def wrap(text)
      should_clearsign = @options[:clearsign] || (@encrypt_to.empty? && @sign_with)
      clearsigned = should_clearsign ? clearsign(text) : text
      @encrypt_to.empty? ? clearsigned : encrypt(clearsigned)
    end

    #
    # Decrypts the signed text and verifies its signature, returns +nil+ unless
    #   the signature correctly verifies against a public key present in +verify_sigs_with+
    #
    # @param [String] Encrypted signed data
    # @return [String] The encrypted data if there is at least one valid signature made
    #   by a configured key
    #
    def unwrap(data)
      @encryptor.decrypt(data) if valid_signature?(data)
    end

    #
    # Checks the validity of the data signature
    #
    # @return [Bool] +true+ if the data is signed with one of the configured keys
    #
    def valid_signature?(data)
      unless @verify_sigs_with.empty?
        correct_sig = false

        @encryptor.verify(data) do |sig| 
          correct_sig = @verify_sigs_with.map(&:fingerprint).include?(sig.key.fingerprint)
        end

        correct_sig
      end
    end

    #
    # Returns +true+ if there is at least one encryption key configured
    # 
    # @return [Boolean] Whether this encryptor is able to encrypt data
    #
    def can_encrypt?
      ![encrypt_to].flatten.empty?
    end


    #
    # Clearsigns the given text with the auditor's GPG key
    #
    # @param text [String] The data to clearsign
    # @return [String] The clearsigned text
    #
    def clearsign(text)
      encryptor.clearsign(text, signer: sign_with)
    end

    #
    # Encrypts the given text with the configured private keys
    #
    # @param text [String] The text to encrypt
    # @return [String] The encrypted text
    #
    def encrypt(text)
      encryptor.encrypt(text, recipients: encrypt_to, always_trust: true, sign: true, signers: sign_with)
    end

  end
end

