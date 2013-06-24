require_relative '../spec_helper'

describe Watchy::GPGKey do


  context 'class mathods' do

    subject { Watchy::GPGKey }

    describe '.gpg_available?' do
      it 'should report the GPG binary presence on the path' do
        subject.should_receive(:system).and_return(true)
        subject.gpg_available?.should be_true
      end

      it 'should report the GPG binary absence when command is not found' do
        subject.should_receive(:system).and_return(false)
        subject.gpg_available?.should be_false
      end
    end
  end

  context 'instance methods' do

    describe '#fingerprint=' do
      before { @fingerprint = 'EF5AD3005FA03C7898F2A98BBECB4E52A92D98D0' }
      subject { Watchy::GPGKey.new(@fingerprint) }

      it 'should set the fingerprint if it is correctly formatted' do
        subject.fingerprint.should eql(@fingerprint)
      end

      it 'should raise an error if the fingerprint is changed' do
        expect { subject.fingerprint = 'EF5AD3005FA03C7898F2A98BBE00000000000000' }.to raise_error
      end
    end
  end
end
