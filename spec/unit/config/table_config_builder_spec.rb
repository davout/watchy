require_relative '../../spec_helper.rb'

describe Watchy::Config::TableConfigBuilder do
  describe '#define_rule' do
    it 'should add an insert rule in the configuration hash' do
      subject.define_rule(:insert) { |a| }
      c = subject.instance_variable_get(:@config)[:rules][:insert]
      c.count.should eql(1)
      c[0].should be_an_instance_of(Watchy::InsertRule)
    end

    it 'should add an update rule in the configuration hash' do
      subject.define_rule(:update) { |a,b| }
      c = subject.instance_variable_get(:@config)[:rules][:update]
      c.count.should eql(1)
      c[0].should be_an_instance_of(Watchy::UpdateRule)
    end
  end
end

