module Watchy

  # 
  # Represents a GPG key that allows verifying signatures as well 
  # as signing messages if the private key is available.
  #
  class GPGKey

    #
    # Returns the key fingerprint
    #
    # @return [String] The key fingerprint
    #
    attr_reader :fingerprint

    #
    # Checks whether the GnuPG binary is available on the system
    #
    # @return [Boolean] Whether GPG is available on the system
    #
    def self.gpg_available?
      system('gpg --version >/dev/null 2>&1')
    end

    #
    # Initializes a key given its fingerprint
    #
    # @param [String] The key fingerprint
    #
    def initialize(fingerprint)
      self.fingerprint = fingerprint
      raise("GPG binary not found") unless GPGKey.gpg_available?
      raise("Secret key unavailable") unless secret_key_available?
      raise("The secret key is passphrase-protected") if passphrase_protected?
    end

    #
    # Checks whether the secret key is available
    #
    # @return [Boolean] Whether the secret key is available
    #
    def secret_key_available?
      `gpg --list-secret-keys #{fingerprint} > /dev/null 2>&1`
      $?.success?
    end

    #
    # Checks whether the secret key is passphrase-protected
    #
    # @return [Boolean] Whether the key is passphrase-protected
    #
    def passphrase_protected?
      `echo foo | gpg --batch --clearsign -u #{@fingerprint} > /dev/null 2>&1`
      !$?.success?
    end

    #
    # Sets the fingerprint if it is empty after checking its format
    #
    # @param [String] The key fingerprint
    #
    def fingerprint=(fingerprint)
      f = fingerprint.gsub(/\s/, '')
      raise("Incorrectly formatted key fingerprint") unless f.match(/\A[A-F0-9]{40}\Z/)
      @fingerprint && raise("Can not change the fingerprint if it is already set")
      @fingerprint = f
    end
  end
end
