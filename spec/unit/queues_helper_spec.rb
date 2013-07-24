require_relative '../spec_helper.rb'

describe Watchy::QueuesHelper do

include Watchy::QueuesHelper

  before { Settings({ broadcast_queue: 'yoo', receive_queue: 'woo' }) }

  describe '#broadcast_queue' do
    it 'should return the configured broadcast queue' do
      broadcast_queue.should eql('yoo')
    end
  end

  describe '#receive_queue' do
    it 'should return the configured receive queue' do
      receive_queue.should eql('woo')
    end
  end

end
