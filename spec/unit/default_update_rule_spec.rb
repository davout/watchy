require_relative '../spec_helper.rb'

describe Watchy::DefaultUpdateRule do
  subject { Watchy::DefaultUpdateRule.new('somefield') }

  describe '#new' do
    it 'should define the default update rule' do
      subject.should be_an_instance_of(Watchy::DefaultUpdateRule)

    end
  end
end

