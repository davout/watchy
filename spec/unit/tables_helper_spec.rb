require_relative '../spec_helper'

describe Watchy::TablesHelper do

  class Dummy; include Watchy::TablesHelper; end

  subject { Dummy.new }

  describe '#bootstrap_audit_tables!' do
    it 'should create missing tables and check the existing ones' do
      subject.stub(:config).and_return({
        audit: {
          tables: {
            foo: { rules: { update: [], insert: [] }},
            bar: { rules: { update: [], insert: [] }},
          }}}) 

      existing_table = mock(Object)
      missing_table = mock(Object)

      existing_table.should_receive(:exists?).once.and_return(true)
      existing_table.should_receive(:check_for_structure_changes!).once
      missing_table.should_receive(:exists?).once.and_return(false)
      missing_table.should_receive(:copy_structure).once
      subject.should_receive(:add_metadata_tables!).once

      Watchy::Table.should_receive(:new).twice.and_return(existing_table, missing_table)

      subject.bootstrap_audit_tables!
    end
  end

  describe '#tables' do
    before do
      subject.stub(:config).and_return({
        audit: {
          tables: {
            'yoodeloo' => { :rules => :foodelaa },
            'yoodelaa' => { :rules => :foodeloo }
          }
        }
      })

      Watchy::Table.stub(:new).and_return(:yoo, :yaa)
    end

    it 'should instantiate a Watchy::Table object for each configured table' do
      Watchy::Table.should_receive(:new).once.ordered.with(subject, 'yoodeloo', :foodelaa)
      Watchy::Table.should_receive(:new).once.ordered.with(subject, 'yoodelaa', :foodeloo)

      subject.tables.should eql([:yoo, :yaa])
    end
  end

  describe '#add_metadata_tables' do
    before do
      subject.stub(:audit_db)
      subject.stub(:connection).and_return(mock(Object).as_null_object)
      Dummy.any_instance.stub(:logger).and_return(mock(Object).as_null_object)
    end

    it 'should execute the creation DDL statements' do
      Watchy::Table.stub(:exists?).and_return(false)
      subject.should_receive(:connection).twice
      subject.add_metadata_tables!
    end

    it 'should not execute the creation DDL statementsi if the table already exists' do
      Watchy::Table.stub(:exists?).and_return(true)
      subject.should_receive(:connection).once
      subject.add_metadata_tables!
    end
  end
end
