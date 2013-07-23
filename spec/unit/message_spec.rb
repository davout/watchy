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
end
