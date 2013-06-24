require_relative '../spec_helper'

describe Watchy::GpgKey do

  describe '.gpg_available?' do

    subject { Watchy::GpgKey }

    it 'should report the GPG binary presence on the path' do
      subject.should_receive(:'`').
        with('gpg --version 2>&1').
        and_return("gpg (GnuPG) 1.4.12\nCopyright (C) 2012 Free Software Foundation, Inc.")

      subject.gpg_available?.should be_true
    end

    it 'should report the GPG binary absence when command is not found' do
      subject.should_receive(:'`') { `some-non-existing-command 2>&1` }
      subject.gpg_available?.should be_false
    end

    it 'should report GPG absence when the returned version string is not recognized' do
      subject.should_receive(:'`') { `whoami` }
      subject.gpg_available?.should be_false
    end
  end
end
