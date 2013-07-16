require_relative '../spec_helper.rb'

describe Watchy::Field do

  subject do
    Watchy::Field.any_instance.stub(:read_rules)
    Watchy::Field.new(Object.new, 'field', 'some-type', nil)
  end

  before do
    table = mock(Object).as_null_object
    table.stub(:audit).and_return("`audit`.`table`")
    table.stub(:watched).and_return("`watched`.`table`")
    subject.stub(:name).and_return('field')
    subject.stub(:table).and_return(table)
  end

  describe '#audit' do
    it 'should return the fully qualified name for the audit field' do
      subject.audit.should eql("`audit`.`table`.`field`")
    end
  end

  describe '#watched' do
    it 'should return the fully qualified name for the watched field' do
      subject.watched.should eql("`watched`.`table`.`field`")
    end
  end

  describe '#difference_filter' do
    before do
      watched = "`watched`.`table`.`field`"
      audit   = "`audit`.`table`.`field`"
      @expected_filter = "((#{watched} IS NULL AND #{audit} IS NOT NULL) OR (#{watched} IS NOT NULL AND #{audit} IS NULL) OR (#{watched} <> #{audit}))"
    end

    it 'should return a SQL WHERE fragment matching when the fields are different' do
      subject.difference_filter.should eql(@expected_filter)
    end
  end
end
