require_relative '../spec_helper'

describe Watchy::GPG do

  subject do
    Watchy::GPG.new('foo')
  end

  before do
    GPGME::Key.stub(:find).and_return(:foo)
  end

  describe '#encryptor' do
    it 'should memoize a new GPGME::Crypto instance' do
      GPGME::Crypto.should_receive(:new).once.and_return(:foo)
      subject.encryptor
      subject.encryptor.should eql(:foo)
    end
  end

  describe '#wrap' do
    it 'should encrypt the supplied text' do
      subject.should_receive(:encrypt).once.with('sekret').and_return('encrypted')
      subject.wrap('sekret').should eql('encrypted')
    end

    context 'when the clearsign option is set' do
      before { subject.instance_variable_set(:@options, { clearsign: true }) }

      it 'should encrypt and clearsign the supplied text' do
        subject.should_receive(:clearsign).once.with('sekret').and_return('clearsigned')
        subject.should_receive(:encrypt).once.with('clearsigned').and_return('encrypted')
        subject.wrap('sekret').should eql('encrypted')
      end
    end
  end

  context 'when working with an ecnryptor' do

    before do 
      @encryptor = mock(Object)
      subject.stub(:encryptor).and_return(@encryptor)
    end

    describe '#clearsign' do
      it 'should clearsign the supplied text' do
        @encryptor.should_receive(:clearsign).once.with('sekret', signer: :foo)
        subject.clearsign('sekret')
      end
    end

    describe '#encrypt' do
      it 'should encrypt the supplied text' do 
        @encryptor.should_receive(:encrypt).once.with('sekret', recipients: [], always_trust: true, sign: true, signers: :foo)
        subject.encrypt('sekret')
      end
    end
  end
end
