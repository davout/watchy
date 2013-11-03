require_relative '../spec_helper.rb'

describe Watchy::InsertRule do

  subject { Watchy::InsertRule.new(:foo) { |inserted_row| } }

  before do
    @table = Object.new
  end

  it 'should call the supplied block when executed' do
    @table.should_receive(:instance_exec).once.with(:some_row, &subject.rule_code)
    subject.execute(:some_row, @table)
  end
end
