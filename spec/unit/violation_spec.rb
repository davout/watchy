require_relative '../spec_helper.rb'

describe Watchy::Violation do

  subject { Watchy::Violation }

  before do
    subject.stub(:db).and_return(Object.new)
    subject.stub(:audit_db).and_return('yoodeloo')
  end

  describe '.signoff' do
    it 'should issue an update if given a correct fingerprint' do
      fpr = 'a' * 64
      subject.db.should_receive(:query).once
      Watchy::Violation.signoff([fpr])
    end
  end

end
