require_relative '../spec_helper'

describe Watchy::TablesHelper do

  class Dummy; include Watchy::TablesHelper; end

  subject { Dummy.new }

  describe '#bootstrap_audit_tables!' do
    it 'should create missing tables and check the existing ones' do
      subject.should_receive(:config).and_return({
        audit: {
          tables: {
            foo: {},
            bar: {}
          }
        }
      })

      existing_table = mock(Object)
      missing_table = mock(Object)

      existing_table.should_receive(:exists?).once.and_return(true)
      existing_table.should_receive(:check_for_structure_changes!).once
      missing_table.should_receive(:exists?).once.and_return(false)
      missing_table.should_receive(:copy_structure).once

      Watchy::Table.should_receive(:new).twice.and_return(existing_table, missing_table)

      subject.bootstrap_audit_tables!
    end
  end
end
