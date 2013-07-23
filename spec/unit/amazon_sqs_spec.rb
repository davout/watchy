require_relative '../spec_helper.rb'

describe Watchy::AmazonSQS do

  before do
    @sqs = Object.new
    @client = Object.new
    @sqs.stub(:queues).and_return({ foo_url: @client })
    AWS::SQS.stub(:new).and_return(@sqs)
  end

  subject do
    Watchy::AmazonSQS.new(:foo, :bar, :foo_url)
  end

  describe '#push_raw' do
    it 'should call the +send_message+ method on the client' do
      @client.should_receive(:send_message).once.with(:yoohoo)
      subject.push_raw(:yoohoo)
    end
  end

  describe '#pop_raw' do
    it 'should call the +receive_message+ method on the client' do
      @client.should_receive(:receive_messages).once
      subject.pop_raw
    end
  end
end
