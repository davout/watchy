require_relative '../spec_helper'

describe Watchy::Report do

  subject do 
    class TestReport < Watchy::Report
      def name
        "world"
      end

      def template
        "Hello {{name}}"
      end
    end

    TestReport.new(nil)
  end

  describe '#do_render' do
    it 'should render a simple template' do
      subject.do_render.should eql('Hello world')
    end
  end

  describe '#generate' do
    it 'should render the report' do
      subject.should_receive(:do_render).once.and_return('miaou schnougoudadisch')
      subject.generate.should eql('miaou schnougoudadisch')
    end
  end

  describe '#due?' do
    before do
      @t = Time.now
      Time.stub(:now).and_return(@t)
      subject.stub(:cron_parser).and_return(true)
    end

    it 'should return true if the @next_run value is in the past' do
      subject.instance_variable_set(:@next_run, @t - 100)
      subject.due?.should be_true
    end

    it 'should return false if the @next_run value is in the future' do
      subject.instance_variable_set(:@next_run, @t + 100)
      subject.due?.should be_false
    end
  end

  describe '#db' do
    before do
      subject.stub(:config).and_return({database: { connection: :bar }})
    end

    it 'should return the DB connection' do
      subject.db.should eql(:bar)
    end
  end

  describe '#broadcast' do
    before do
      @bq = Object.new
      subject.stub(:config).and_return({broadcast_queue: @bq})
    end

    it 'should push a message to the queue' do
      subject.should_receive(:generate).once.and_return('hello!')
      @bq.should_receive(:push).once.with('hello!')
      subject.broadcast!
    end
  end
end
