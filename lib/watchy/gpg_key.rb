module Watchy

  # 
  # Represents a GPG key that allows verifying signatures as well 
  # as signing messages if the private key is available.
  #
  class GpgKey

    #
    # Checks whether the GnuPG binary is available on the system
    #
    def self.gpg_available?
      version_summary = `gpg --version 2>&1`.
        encode!('UTF-8', 'UTF-8', invalid: :replace).
        split("\n")[0]

      $?.to_i.zero? && version_summary.match(/GnuPG/)
    end
  end
end


