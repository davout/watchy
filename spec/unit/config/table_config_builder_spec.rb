require_relative '../../spec_helper.rb'

describe Watchy::Config::TableConfigBuilder do
  describe '#on_update' do
    it 'should add an update rule' do 
      Watchy::UpdateRule.should_receive(:new)
      subject.on_update { |a,b| }
    end
  end

  describe '#on_insert' do
    it 'should add an insert rule' do 
      Watchy::InsertRule.should_receive(:new)
      subject.on_insert { |a| }
    end
  end

  describe '#on_delete' do
    it 'should add a delete rule' do 
      Watchy::DeleteRule.should_receive(:new)
      subject.on_delete { |a| }
    end
  end
end

