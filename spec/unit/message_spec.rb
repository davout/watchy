require_relative '../spec_helper'

describe Watchy::Message do

  subject { Watchy::Message.new('message') }

  describe '.handle' do
    it 'should instantiate a message and call its +handle+ method' do
      Watchy::Message.should_receive(:new).once.with('foo').and_call_original
      Watchy::Message.any_instance.should_receive(:handle).once.and_return(:baz)
      Watchy::Message.handle('foo')
    end
  end

  describe '#handle' do
    it 'should handle a SIGNOFF command' do
      subject.should_receive(:body).and_return('SIGNOFF|foongerprint')
      Watchy::Violation.should_receive(:signoff).once.with(['foongerprint'])
      subject.handle
    end

    it 'should raise an error when an invalid command is handled' do
      subject.should_receive(:body).and_return('BUGGY_COMMAND')
      expect { subject.handle }.to raise_error
    end
  end
end
