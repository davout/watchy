require_relative '../spec_helper.rb'

describe Watchy::InsertRule do

  subject { Watchy::InsertRule.new(:foo) { |inserted_row| } }

  before do
    rc = double(Object).as_null_object
    subject.stub(:rule_code).and_return(rc)
  end

  it 'should call the supplied block when executed' do
    subject.rule_code.should_receive(:call).once.with(:some_row)
    subject.execute(:some_row)
  end
end
