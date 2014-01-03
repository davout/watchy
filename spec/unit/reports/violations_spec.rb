require_relative '../../spec_helper.rb'

describe Watchy::Reports::Violations do

  subject { Watchy::Reports::Violations.new }

  describe '#generated_at' do
    it 'should return a Time instance' do
      subject.generated_at.should be_an_instance_of(Time)
    end
  end

  describe '#template' do
    it 'should return a string' do
      subject.template.should be_an_instance_of(String)
    end
  end

  describe '#due?' do
    it 'should return false since we have no crondef' do
      subject.due?.should be_false
    end
  end

  describe '#violations' do
    it 'should query the DB ro return the pending violations' do
      subject.db.should_receive(:query)
      subject.violations
    end
  end

  describe '#signoff_command' do
    before do
      subject.stub(:db).and_return(Object.new)
      subject.db.stub(:query).and_return([{ 'fingerprint' => 'a' }, 
                                          { 'fingerprint' => 'b' }, 
                                          { 'fingerprint' => 'c' }]) 
    end

    it 'should return the correct command' do
      subject.signoff_command.should eql('a,b,c')
    end
  end
end
