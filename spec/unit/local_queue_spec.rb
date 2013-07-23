require_relative '../spec_helper'

describe Watchy::LocalQueue do

  subject { Watchy::LocalQueue.new }

  before do
    @queue = [:foodeloo]
    subject.instance_variable_set(:@queue, @queue)
  end

  describe '#push_raw' do
    it 'should push messages to the underlying array' do
      @queue.should_receive(:<<).with(:msg)
      subject.push_raw(:msg)
    end
  end

  describe '#pop_raw' do
    it 'should shift an element from the array' do
      @queue.should_receive(:shift).and_call_original
      subject.pop_raw.should eql(:foodeloo)
    end
  end
end

