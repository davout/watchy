require_relative '../spec_helper'

describe Watchy::Queue do

  subject { Watchy::Queue.new }

  before do
    @queue = [:foodeloo]
    subject.instance_variable_set(:@queue, @queue)
  end

  describe '#push' do
    it 'should wrap the element and call the underlying backend' do
      subject.should_receive(:wrap).with(:foo).once.and_return(:bar)
      subject.should_receive(:push_raw).with(:bar).once
      subject.push(:foo)
    end
  end

  describe '#pop' do
    it 'should unwrap the element given by the underlying backend' do
      subject.should_receive(:pop_raw).once.and_return(:yibidee)
      subject.should_receive(:unwrap).with(:yibidee).once.and_return(:yadabadoo)
      subject.pop.should eql(:yadabadoo)
    end
  end

  context 'when working with GPG' do
    before do
      @gpg = Object.new
      @gpg.stub(:can_encrypt?).and_return(true)
      subject.stub(:gpg).and_return(@gpg)
    end

    describe '#wrap' do
      it 'should delegate the wrapping to the gpg wrapper' do
        @gpg.should_receive(:wrap).once.with(:foo).and_return(:bar)
        subject.wrap(:foo).should eql(:bar)
      end
    end

    describe '#unwrap' do
      it 'should delegate the wrapping to the gpg wrapper' do
        @gpg.should_receive(:unwrap).once.with(:foo).and_return(:bar)
        subject.unwrap(:foo).should eql(:bar)
      end
    end
  end
end
