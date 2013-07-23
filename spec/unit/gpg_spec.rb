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

  describe '#can_encrypt?' do
    it 'should return true if encryption keys are present' do
      subject.should_receive(:encrypt_to).once.and_return(:foo)
      subject.can_encrypt?.should be_true
    end

    it 'should return false if no encryption keys are present' do
      subject.should_receive(:encrypt_to).once.and_return(nil)
      subject.can_encrypt?.should be_false
    end
  end

  describe '#unwrap' do
    before do
      @encryptor = Object.new
      subject.stub(:encryptor).and_return(@encryptor)
    end

    it 'should decrypt the contents after verifying the signature' do
      subject.should_receive(:valid_signature?).once.with(:foo).and_return(true)
      subject.encryptor.should_receive(:decrypt).once.with(:foo).and_return(:bar)
      subject.unwrap(:foo).should eql(:bar)
    end
  end

  describe '#verify_signature' do
    before do
      @encryptor = Object.new
      subject.stub(:encryptor).and_return(@encryptor)
      subject.instance_variable_set(:@verify_sigs_with, [:foo])
    end

    it 'should verify the signature of the given data' do
      @encryptor.should_receive(:verify).with(:foodeloo)
      subject.valid_signature?(:foodeloo)
    end
  end

  describe '#wrap' do
    context 'no encryption keys are set' do
      it 'should clearsign the supplied text' do
        subject.should_receive(:clearsign).once.with('sekret').and_return('clearsigned')
        subject.wrap('sekret').should eql('clearsigned')
      end
    end

    context 'encryption keys are set' do
      before { subject.encrypt_to = [:fookey] }

      it 'should not clearsign but sign and encrypt the supplied text' do
        subject.should_receive(:encrypt).once.with('sekret').and_return('encrypted')
        subject.wrap('sekret').should eql('encrypted')
      end
    end

    context 'when the clearsign option is set' do
      before do
        subject.instance_variable_set(:@options, { clearsign: true })
        subject.encrypt_to = [:fookey]
      end

      it 'should encrypt and clearsign the supplied text' do
        subject.should_receive(:clearsign).once.with('sekret').and_return('clearsigned')
        subject.should_receive(:encrypt).once.with('clearsigned').and_return('encrypted')
        subject.wrap('sekret').should eql('encrypted')
      end
    end
  end

  context 'when working with an encryptor' do
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
