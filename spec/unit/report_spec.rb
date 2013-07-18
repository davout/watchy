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

    TestReport.new({ database: {} }, nil)
  end

  describe '#do_render' do
    it 'should render a simple template' do
      subject.do_render.should eql('Hello world')
    end
  end

  describe '#generate' do
    before do
      @gpg = mock(Object)
      subject.stub(:gpg).and_return(@gpg)
    end

    it 'should wrap the rendered report in a GPG envelope' do
      subject.should_receive(:do_render).once.and_return('miaou schnougoudadisch')
      @gpg.should_receive(:wrap).once.with('miaou schnougoudadisch').and_return('klakendaschen')
      subject.generate.should eql('klakendaschen')
    end
  end

end
