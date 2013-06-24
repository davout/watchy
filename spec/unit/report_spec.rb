require_relative '../spec_helper'

describe Watchy::Report do

  describe '#run' do
    before do
      class TestReport < Watchy::Report
        def name
          "world"
        end

        def template
          "Hello {{name}}"
        end
      end
    end

    subject { TestReport.new }

    it 'should render a simple template' do
      subject.render.should eql('Hello world')
    end
  end
end
