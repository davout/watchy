require_relative '../spec_helper.rb'

describe Watchy::UpdateRule do

  subject { Watchy::UpdateRule.new(:foo) { |row1, row2| } }

  before do
    rc = double(Object).as_null_object
    subject.stub(:rule_code).and_return(rc)
  end

  it 'should call the supplied block when executed' do
    subject.rule_code.should_receive(:call).once.with(:r1, :r2)
    subject.execute(:r1, :r2)
  end
end
