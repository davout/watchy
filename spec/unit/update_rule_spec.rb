require_relative '../spec_helper.rb'

describe Watchy::UpdateRule do

  subject { Watchy::UpdateRule.new(:foo) { |row1, row2| } }

  before do
    @table = Object.new
  end

  it 'should call the supplied block when executed' do
    @table.should_receive(:instance_exec).once.with(:r1, :r2, &subject.rule_code)
    subject.execute(:r1, :r2, @table)
  end
end
