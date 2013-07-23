require_relative '../spec_helper.rb'

describe Watchy::Field do

  subject do
    table = Object.new
    auditor = Object.new

    auditor.stub(:config).and_return({
      audit: {
        tables: {
          sometable: {
            fields: {}
          }
        }
      }
    })

    Watchy::Field.any_instance.stub(:table).and_return(table)
    table.stub(:auditor).and_return(auditor)
    table.stub(:name).and_return('sometable')
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

  describe '#rules' do
    it 'should return the rules' do
      puts subject.instance_variable_get(:@rules).inspect
      subject.rules(:update)[0].should be_an_instance_of(Watchy::DefaultUpdateRule)
    end
  end


  context 'when running rules' do
    before do
      @watched_row = Object.new
      @audit_row = Object.new
      @some_rule = Object.new
      @some_rule.stub(:name).and_return('foodeloo')
    end

    describe '#on_insert' do
      it 'should record a violation' do
        subject.should_receive(:rules).once.with(:insert).and_return([@some_rule])
        @some_rule.should_receive(:execute).once.with(@audit_row).and_return('boo')
        subject.on_insert(@audit_row).should eql([{
          rule_name: 'foodeloo',
          description: 'boo',
          item: @audit_row
        }])
      end
    end

    describe '#on_update' do
      it 'should record a violation' do
        subject.should_receive(:rules).once.with(:update).and_return([@some_rule])
        @some_rule.should_receive(:execute).once.with(@watched_row, @audit_row).and_return('boo')
        subject.on_update(@watched_row, @audit_row).should eql([{
          rule_name: 'foodeloo',
          description: 'boo',
          item: [@watched_row, @audit_row]
        }])
      end
    end
  end
end
