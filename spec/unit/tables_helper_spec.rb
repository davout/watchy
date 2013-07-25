require_relative '../spec_helper'

describe Watchy::TablesHelper do

  class Dummy; include Watchy::TablesHelper; end

  subject { Dummy.new }

  before do
    Settings.stub(:[]).and_return({
      tables: {
        yoodeloo: { :rules => { update: [], insert: [], delete: [] }, :versioning_enabled => 42 },
        yoodelaa: { :rules => { update: [], insert: [], delete: [] }, :versioning_enabled => 69 }
      }})
  end

  describe '#bootstrap_audit_tables!' do
    it 'should create missing tables and check the existing ones' do

      existing_table = double(Object)
      missing_table = double(Object)

      existing_table.should_receive(:exists?).once.and_return(true)
      existing_table.should_receive(:check_for_structure_changes!).once
      missing_table.should_receive(:exists?).once.and_return(false)
      missing_table.should_receive(:copy_structure).once
      missing_table.should_receive(:create_versioning_table).once
      subject.should_receive(:add_metadata_tables!).once

      Watchy::Table.should_receive(:new).twice.and_return(existing_table, missing_table)

      subject.bootstrap_audit_tables!
    end
  end

  describe '#tables' do
    before { Watchy::Table.stub(:new).and_return(:yoo, :yaa) }

    it 'should instantiate a Watchy::Table object for each configured table' do
      Watchy::Table.should_receive(:new).once.ordered.with(subject, 'yoodeloo', { update: [], insert: [], delete: [] }, 42)
      Watchy::Table.should_receive(:new).once.ordered.with(subject, 'yoodelaa', { update: [], insert: [], delete: [] }, 69)

      subject.tables.should eql([:yoo, :yaa])
    end
  end

  describe '#add_metadata_tables' do
    before do
      subject.stub(:audit_db)
      subject.stub(:db).and_return(double(Object).as_null_object)
      Dummy.any_instance.stub(:logger).and_return(double(Object).as_null_object)
    end

    it 'should execute the creation DDL statements' do
      Watchy::Table.stub(:exists?).and_return(false)
      subject.should_receive(:db).twice
      subject.add_metadata_tables!
    end

    it 'should not execute the creation DDL statements if the table already exists' do
      Watchy::Table.stub(:exists?).and_return(true)
      subject.should_receive(:db).once
      subject.add_metadata_tables!
    end
  end
end
