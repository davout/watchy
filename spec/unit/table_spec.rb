require_relative '../spec_helper.rb'

describe 'Watchy::Table' do

  subject { Watchy::Table.new(mock(Object).as_null_object, 'baz') }

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
      f = [ Watchy::Field.new(subject, 'foo', 'INT', false, true), Watchy::Field.new(subject, 'bar', 'INT') ]
      subject.stub(:fields).and_return(f)
    end

    it 'should return the primary key fields as an array of field names' do
      subject.primary_key.should eql(%w{ foo })
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
      subject.connection.stub(:query).and_return([], [{ 'Field' => 'copied_at' }])
      subject.logger.should_receive(:info)
      subject.check_for_structure_changes!
    end

    it 'should fail when the copied_at field is not present in the audit table' do
      subject.connection.stub(:query).and_return([], [])
      expect { subject.check_for_structure_changes! }.to raise_error("Missing 'copied_at' field in audit table 'baz'!")
    end
  end

  describe '#add_copied_at_field' do
    it 'should issue the correct ALTER statement to the database' do
      subject.auditor.should_receive(:audit_db).once.and_return('foo')
      subject.connection.should_receive(:query).with("ALTER TABLE `foo`.`baz` ADD `copied_at` TIMESTAMP NULL").once
      subject.add_copied_at_field
    end
  end

  describe '#stamp_new_rows' do
    it 'should issue the correct UPDATE statement to the database' do
      subject.auditor.should_receive(:audit_db).once.and_return('foo')
      subject.connection.should_receive(:query).with("UPDATE `foo`.`baz` SET `copied_at` = NOW() WHERE `copied_at` IS NULL").once
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
    it 'should return a SQL fragment' do
      subject.columns = %w{ id field other_field }
      expected_filter = "(((`audit`.`baz`.`field` IS NULL AND `watched`.`baz`.`field` IS NOT NULL) OR (`audit`.`baz`.`field` IS NULL AND `watched`.`baz`.`field` IS NOT NULL)) OR (`audit`.`baz`.`field` <> `watched`.`baz`.`field`))"
      subject.differences_filter.should_be eql(expected_filter)
    end
  end
end
