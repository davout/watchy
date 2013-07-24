require_relative '../spec_helper.rb'

describe 'Watchy::Table' do

  subject do 
    Watchy::Table.new(double(Object).as_null_object, 'baz', { update: [], insert: []})
  end

  before do
    subject.stub(:audit_db).and_return('yoo')
    subject.stub(:watched_db).and_return('yaa')
  end

  describe '#watched' do
    it 'should return the fully qualified audited table name' do
      subject.should_receive(:watched_db).once.and_return('foo')
      subject.should_receive(:identifier).once.with('foo').and_call_original
      subject.watched.should eq('`foo`.`baz`')
    end
  end

  describe '#audit' do
    it 'should return the fully qualified audit table name' do
      subject.should_receive(:audit_db).once.and_return('bar')
      subject.should_receive(:identifier).once.with('bar').and_call_original
      subject.audit.should eq('`bar`.`baz`')
    end
  end

  describe '#versioning' do
    it 'should return the fully qualified versioning table name' do
      subject.should_receive(:audit_db).once.and_return('bar')
      subject.should_receive(:identifier).once.with('bar', '_v_baz').and_call_original
      subject.versioning.should eq('`bar`.`_v_baz`')
    end
  end

  describe '#primary_key' do
    before do
      f = [ Watchy::Field.new(subject, 'foo', 'INT', false, true), Watchy::Field.new(subject, 'bar', 'INT', nil) ]
      subject.stub(:fields).and_return(f)
    end

    it 'should return the primary key fields as an array of field names' do
      subject.primary_key.should eql(%w{ foo })
    end
  end

  describe '#fields' do
    before do
      @db = double(Object).as_null_object
      subject.stub(:db).and_return(@db)
    end

    it 'should instantiate an array of fields' do
      @db.should_receive(:query).and_return([{}, {}])
      Watchy::Field.should_receive(:new).twice.and_return(:foo, :bar)
      subject.fields.should eql([:foo, :bar])
    end
  end

  describe '#exists?' do
    it 'should correctly test for the existence of the audit table' do
      subject.db.should_receive(:query).
        and_return([{ 'fizz' => 'baz' }])

      subject.exists?.should be_true
    end
  end

  describe '#copy_structure' do
    it 'should copy the audited table structure and add the copied_at field' do
      subject.stub(:watched_db).and_return('bar')
      subject.stub(:audit_db).and_return('foo')
      subject.db.should_receive(:query).with("CREATE TABLE `foo`.`baz` LIKE `bar`.`baz`")
      subject.should_receive(:add_copied_at_field)
      subject.copy_structure
    end
  end

  describe '#check_for_structure_changes!' do
    it 'should fail when changes are detected' do
      subject.db.stub(:query).and_return([{ 'Field' => 'hello_there' }], [])
      expect { subject.check_for_structure_changes! }.to raise_error("Structure has changed for table 'baz'!")
    end

    it 'should succeed if the audit table has an extra copied_at field' do
      subject.db.stub(:query).and_return([], [{ 'Field' => '_copied_at' }, 
                                              { 'Field' => '_has_delta' }, 
                                              { 'Field' => '_last_version' }, 
                                              { 'Field' => '_has_violation' },
                                              { 'Field' => '_deleted_at' } ])

      subject.logger.should_receive(:info)
      subject.check_for_structure_changes!
    end

    it 'should fail when the metadata fields are not present in the audit table' do
      subject.db.stub(:query).and_return([], [])
      expect { subject.check_for_structure_changes! }.to raise_error
    end
  end

  describe '#add_copied_at_field' do
    it 'should issue the correct ALTER statement to the database' do
      subject.should_receive(:audit_db).once.and_return('foo')
      subject.db.should_receive(:query).with("ALTER TABLE `foo`.`baz` ADD `_copied_at` TIMESTAMP NULL").once
      subject.add_copied_at_field
    end
  end

  describe '#stamp_new_rows' do
    it 'should issue the correct UPDATE statement to the database' do
      subject.should_receive(:audit_db).once.and_return('foo')
      subject.db.should_receive(:query).with("UPDATE `foo`.`baz` SET `_copied_at` = NOW() WHERE `_copied_at` IS NULL").once
      subject.stamp_new_rows
    end
  end

  describe '#copy_new_rows' do
    before { subject.stub(:pkey_equality_condition) }

    it 'should return the number of inserted rows' do
      subject.db.should_receive(:query).twice.and_return(nil, [{ 'COUNT(*)' => 10 }])
      subject.copy_new_rows.should eql(10)
    end
  end

  describe '#differences_filter' do
    before do
      field1 = double(Object).as_null_object
      field2 = double(Object).as_null_object
      field1.stub(:difference_filter).and_return('zibidee')
      field2.stub(:difference_filter).and_return('doo')
      subject.stub(:fields).and_return([field1, field2])
    end

    it 'should return a SQL fragment' do
      expected_filter = "((zibidee) OR (doo))"
      subject.differences_filter.should eql(expected_filter)
    end
  end

  describe '#pkey_equality_condition' do
    before do
      subject.stub(:primary_key).and_return(['a', 'b'])
      subject.stub(:watched).and_return('`foo`')
      subject.stub(:audit).and_return('`bar`')
    end

    it 'should return the correct condition given a primary key' do
      expected = "(`foo`.`a` = `bar`.`a` AND `foo`.`b` = `bar`.`b`)"
      subject.pkey_equality_condition.should eql(expected)
    end
  end

  describe '#flag_row_deltas' do
    before do
      subject.db.stub(:query).and_return([{ 'id' => 42 }])
      subject.stub(:primary_key).and_return(['id'])
      subject.stub(:differences_filter)
      subject.stub(:audit).and_return('`yoodeloo`')
    end

    it 'should flag the rows identified as being different' do
      subject.db.should_receive(:query)
      subject.db.should_receive(:query).
        with("UPDATE `yoodeloo` SET `_has_delta` = 1 WHERE ((`yoodeloo`.`id` = 42))")

      subject.flag_row_deltas
    end
  end

  describe '#unflag_row_deltas' do
    before { subject.stub(:audit).and_return('`klakendaschen`') }

    it 'should issue the correct update statement' do
      subject.db.should_receive(:query).once.with('UPDATE `klakendaschen` SET `_has_delta` = 0')
      subject.unflag_row_deltas
    end
  end

  describe '#record_violation' do

    before do
      c = double(Object).as_null_object
      subject.stub(:db).and_return(c)
    end

    it 'should record an audit violation correctly' do
      subject.db.should_receive(:query).once.and_return([{ 'CNT' => 0 }])
      subject.db.should_receive(:query).twice
      subject.db.should_receive(:escape).exactly(4).times
      subject.record_violation('pouet', {}, 'prutendelschnitzeln', 0)
    end
  end

  describe '#check_rules_on_update' do
    it 'should check all update rules at the row and field levels' do
      some_field = Object.new
      some_rule = Object.new

      subject.db.should_receive(:query).and_return([{ 'id' => 1 }])
      subject.should_receive(:primary_key).and_return(['id'])
      subject.should_receive(:fields).and_return([some_field])
      some_field.should_receive(:on_update).and_return([])
      subject.should_receive(:rules).and_return({ update: [some_rule]})
      some_rule.should_receive(:execute)

      subject.check_rules_on_update
    end
  end

  describe '#check_rules_on_insert' do
    it 'should check all insert rules at the row and field levels' do
      some_field = Object.new
      some_rule = Object.new

      subject.db.should_receive(:query).and_return([{ 'id' => 1 }])
      subject.should_receive(:primary_key).and_return(['id'])
      subject.should_receive(:fields).and_return([some_field])
      some_field.should_receive(:on_insert).and_return([])
      subject.should_receive(:rules).and_return({ insert: [some_rule]})
      some_rule.should_receive(:execute)

      subject.check_rules_on_insert
    end
  end

  describe '#check_deletions' do
    before do
      subject.stub(:condition_from_hashes)
      Watchy::Table.any_instance.stub(:primary_key).and_return(['id'])
      @rule = Object.new
      @rule.stub(:name)
    end

    it 'should check for deletions' do
      subject.db.should_receive(:query).once.ordered.and_return([:foo])
      subject.db.should_receive(:query).once.ordered.and_return([{}])
      subject.should_receive(:rules).and_return({delete: [@rule]})
      @rule.should_receive(:execute).and_return(:foo)
      subject.should_receive(:record_violation)
      subject.db.should_receive(:query).once.ordered
      subject.check_deletions
    end
  end

  describe '#create_versioning_table' do
    before do
      subject.primary_key
      subject.stub(:versioning).and_return('baz')
    end 

    it 'should create the versioning table, update the PK and remove unique indexes from it' do
      c = subject.db
      c.should_receive(:query).once.ordered
      c.should_receive(:query).once.ordered
      c.should_receive(:query).once.ordered
      c.should_receive(:query).once.ordered.and_return([{ 'Table' => 'foo', 'Create Table' => 'UNIQUE KEY `foo`, UNIQUE KEY `bar`'}])
      c.should_receive(:query).once.ordered.with('ALTER TABLE baz DROP INDEX `foo`')
      c.should_receive(:query).once.ordered.with('ALTER TABLE baz DROP INDEX `bar`')
      subject.create_versioning_table
    end
  end

  describe '#assignment_from_hash' do
    it 'should create an assignment string' do
      subject.assignment_from_hash({ 'id' => 42, name: 'Foo' }, 'fooTable').
        should eql("fooTable.`id` = 42, fooTable.`name` = 'Foo'") 
    end
  end

  context 'when working with versioning' do
    before do
      subject.stub(:versioning_enabled).and_return(true) 
      subject.stub(:fields).and_return([])
    end

    describe '#version_inserted_rows' do
      it 'should copy a row version to the versioning table' do
        subject.db.should_receive(:query).twice
        subject.version_inserted_rows
      end
    end

    describe '#version_flagged_rows' do
      it 'should copy a version for the flagged rows' do
        subject.db.should_receive(:query).twice
        subject.version_flagged_rows
      end
    end
  end

  describe '#update_audit_table' do
    it 'should copy the watched DB modifications to the audit DB if possible' do
      subject.stub(:pkey_selection)
      subject.db.should_receive(:query).once.ordered.and_return([[]])
      subject.db.should_receive(:query).twice.ordered.and_return([{}], nil)
      subject.update_audit_table
    end
  end
end
