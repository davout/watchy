require_relative '../spec_helper.rb'

describe 'Watchy::Table' do

  subject { Watchy::Table.new(mock(Object).as_null_object, 'baz', { update: [], insert: []}) }

  describe '#watched' do
    it 'should return the fully qualified audited table name' do
      subject.auditor.should_receive(:watched_db).once.and_return('foo')
      subject.should_receive(:identifier).once.with('foo').and_call_original
      subject.watched.should eq('`foo`.`baz`')
    end
  end

  describe '#audit' do
    it 'should return the fully qualified audit table name' do
      subject.auditor.should_receive(:audit_db).once.and_return('bar')
      subject.should_receive(:identifier).once.with('bar').and_call_original
      subject.audit.should eq('`bar`.`baz`')
    end
  end

  describe '#primary_key' do
    before do
      f = [ Watchy::Field.new(subject, 'foo', 'INT', nil, false, true), Watchy::Field.new(subject, 'bar', 'INT', nil) ]
      subject.stub(:fields).and_return(f)
    end

    it 'should return the primary key fields as an array of field names' do
      subject.primary_key.should eql(%w{ foo })
    end
  end

  describe '#fields' do
    before do
      @connection = mock(Object).as_null_object
      subject.stub(:connection).and_return(@connection)
    end

    it 'should instantiate an array of fields' do
      @connection.should_receive(:query).and_return([{}, {}])
      Watchy::Field.should_receive(:new).twice.and_return(:foo, :bar)
      subject.fields.should eql([:foo, :bar])
    end
  end

  describe '#exists?' do
    it 'should correctly test for the existence of the audit table' do
      subject.auditor.should_receive(:audit_db).once.and_return('baz')
      subject.connection.should_receive(:query).
        with("SHOW TABLES FROM `baz`").
        and_return([{ 'fizz' => 'baz' }])

      subject.exists?.should be_true
    end
  end

  describe '#copy_structure' do
    it 'should copy the audited table structure and add the copied_at field' do
      subject.auditor.stub(:watched_db).and_return('bar')
      subject.auditor.stub(:audit_db).and_return('foo')
      subject.connection.should_receive(:query).with("CREATE TABLE `foo`.`baz` LIKE `bar`.`baz`")
      subject.should_receive(:add_copied_at_field)
      subject.copy_structure
    end
  end

  describe '#check_for_structure_changes!' do
    it 'should fail when changes are detected' do
      subject.connection.stub(:query).and_return([{ 'Field' => 'hello_there' }], [])
      expect { subject.check_for_structure_changes! }.to raise_error("Structure has changed for table 'baz'!")
    end

    it 'should succeed if the audit table has an extra copied_at field' do
      subject.connection.stub(:query).and_return([], [{ 'Field' => '_copied_at' }, { 'Field' => '_has_delta'}])
      subject.logger.should_receive(:info)
      subject.check_for_structure_changes!
    end

    it 'should fail when the copied_at field is not present in the audit table' do
      subject.connection.stub(:query).and_return([], [])
      expect { subject.check_for_structure_changes! }.to raise_error("Missing meta-data fields in audit table 'baz'!")
    end
  end

  describe '#add_copied_at_field' do
    it 'should issue the correct ALTER statement to the database' do
      subject.auditor.should_receive(:audit_db).once.and_return('foo')
      subject.connection.should_receive(:query).with("ALTER TABLE `foo`.`baz` ADD `_copied_at` TIMESTAMP NULL").once
      subject.add_copied_at_field
    end
  end

  describe '#stamp_new_rows' do
    it 'should issue the correct UPDATE statement to the database' do
      subject.auditor.should_receive(:audit_db).once.and_return('foo')
      subject.connection.should_receive(:query).with("UPDATE `foo`.`baz` SET `_copied_at` = NOW() WHERE `_copied_at` IS NULL").once
      subject.stamp_new_rows
    end
  end

  describe '#copy_new_rows' do
    before { subject.stub(:pkey_equality_condition) }

    it 'should return the number of inserted rows' do
      subject.connection.should_receive(:query).twice.and_return(nil, [{ 'COUNT(*)' => 10 }])
      subject.copy_new_rows.should eql(10)
    end
  end

  describe '#differences_filter' do
    before do
      field1 = mock(Object).as_null_object
      field2 = mock(Object).as_null_object
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
      subject.connection.stub(:query).and_return([{ 'id' => 42 }])
      subject.stub(:primary_key).and_return(['id'])
      subject.stub(:differences_filter)
      subject.stub(:audit).and_return('`yoodeloo`')
    end

    it 'should flag the rows identified as being different' do
      subject.connection.should_receive(:query)
      subject.connection.should_receive(:query).
        with("UPDATE `yoodeloo` SET `_has_delta` = 1 WHERE ((`yoodeloo`.`id` = 42))")

      subject.flag_row_deltas
    end
  end

  describe '#unflag_row_deltas' do
    before { subject.stub(:audit).and_return('`klakendaschen`') }

    it 'should issue the correct update statement' do
      subject.connection.should_receive(:query).once.with('UPDATE `klakendaschen` SET `_has_delta` = 0')
      subject.unflag_row_deltas
    end
  end

  describe '#record_violation' do

    before do
      c = mock(Object).as_null_object
      subject.stub(:connection).and_return(c)
    end

    it 'should record an audit violation correctly' do
      subject.connection.should_receive(:query).once.and_return([{ 'CNT' => 0 }])
      subject.connection.should_receive(:query).once
      subject.connection.should_receive(:escape).twice
      subject.record_violation('pouet', {}, 'prutendelschnitzeln')
    end
  end

  describe '#check_rules_on_update' do
    it 'should check all rules defined on the row and all rules defined on all fields' do
      subject.connection.should_receive(:query).and_return([{ 'id' => 1 }])
      subject.should_receive(:primary_key).and_return(['id'])
      subject.should_receive(:fields).and_return([])

      subject.check_rules_on_update
    end
  end

  describe '#check_rules_on_insert' do
  end

end
