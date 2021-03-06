require_relative '../spec_helper'

describe Watchy::LoggerHelper do

  class Dummy; include Watchy::LoggerHelper; end

  subject { Dummy.new }

  describe '#logger' do
    before do

      @l = Object.new
      Settings.stub(:[]).and_return({
        logger: @l,
        level: 'bar'
      })

      @l.stub(:level=)

      Watchy::LoggerHelper.class_variable_set(:@@logger, nil)
    end

    it 'should set the loglevel once and return the logger' do
      Watchy::LoggerHelper.should_receive(:eval).once.with('Logger::Severity::BAR')
      subject.logger
      subject.logger.should eql(@l)
    end
  end
end
