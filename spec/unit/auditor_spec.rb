require_relative '../spec_helper'

describe Watchy::Auditor do

  before do
    Watchy::Auditor.any_instance.stub(:bootstrap_databases!)
    Watchy::Auditor.any_instance.stub(:bootstrap_audit_tables!)
    Watchy::Auditor.any_instance.stub(:logger).and_return(mock(Object).as_null_object)
  end

  subject do
    Watchy::Auditor.new({
      database: {
        schema: 'foo',
        audit_schema: 'bar'
      },

      gpg: :foo
    })
  end

  describe '#interrupt!' do
    before do
    end

    it 'should set the interrupted instance variable' do
      subject.interrupted.should be_false
      subject.logger.should_receive(:info)
      subject.interrupt!
      subject.interrupted.should be_true
    end
  end

  describe '.new' do
    it 'should bootstrap the databases' do 
      subject.should_receive(:bootstrap_databases!)
    end

    it 'should bootstrap the audit tables' do 
      subject.should_receive(:bootstrap_audit_tables!).once
    end

    after { subject.send(:initialize, subject.config) }
  end

  describe '#run' do
    before do
      subject.stub(:interrupted).and_return(false, true)
      subject.stub(:sleep_for)
      subject.stub(:stamp_new_rows)
      subject.stub(:copy_new_rows)
      subject.stub(:run_reports!)
      subject.stub(:flag_row_deltas)
      subject.stub(:unflag_row_deltas)
      subject.stub(:check_rules)
      subject.stub(:version_flagged_rows)
      subject.stub(:version_inserted_rows)
      subject.stub(:update_audit_tables)
      subject.stub(:check_deletions)
      subject.stub(:receive_and_handle_messages)
    end

    it 'should copy new rows to the audit database' do
      subject.should_receive :copy_new_rows
    end

    it 'should timestamp new rows with the current time' do
      subject.should_receive :stamp_new_rows
    end

    it 'should run the reports' do
      subject.should_receive :run_reports!
    end

    after do
      subject.send(:run!)
    end
  end

  describe 'when working with tables' do
    before { subject.stub(:tables).and_return([Object, Object, Object]) }

    describe '#flag_row_deltas' do
      it 'should call Table#flag_row_deltas for each audited table' do
        subject.tables.each { |t| t.should_receive(:flag_row_deltas).once }
        subject.flag_row_deltas
      end
    end

    describe '#unflag_row_deltas' do
      it 'should call Table#funlag_row_deltas for each audited table' do
        subject.tables.each { |t| t.should_receive(:unflag_row_deltas).once }
        subject.unflag_row_deltas
      end
    end

    describe '#copy_new_rows' do
      it 'should call Table#copy_new_rows for each audited table' do
        subject.tables.each { |t| t.should_receive(:copy_new_rows).once }
        subject.copy_new_rows
      end
    end

    describe '#stamp_new_rows' do
      it 'should call Table#stamp_new_rows for each audited table' do
        subject.tables.each { |t| t.should_receive(:stamp_new_rows).once }
        subject.stamp_new_rows
      end
    end

    describe '#check_deletions' do
      it 'should call Table#check_deletions for each audited table' do
        subject.tables.each { |t| t.should_receive(:check_deletions).once }
        subject.check_deletions
      end
    end

    describe '#update_audit_table' do
      it 'should call Table#update_audit_table for each audited table' do
        subject.tables.each { |t| t.should_receive(:update_audit_table).once }
        subject.update_audit_tables
      end
    end

    describe '#version_flagged_rows' do
      it 'should call Table#version_flagged_rows for each audited table' do
        subject.tables.each { |t| t.should_receive(:version_flagged_rows).once }
        subject.version_flagged_rows
      end
    end

    describe '#check_rules' do
      it 'should call Table#check_rules for each audited table' do
        subject.tables.each { |t| t.should_receive(:check_rules_on_update).once }
        subject.tables.each { |t| t.should_receive(:check_rules_on_insert).once }
        subject.check_rules
      end
    end
  end

  describe 'when working with reports' do
    before do
      @due_report   = Object.new
      @undue_report = Object.new

      @due_report.stub(:due?).and_return(true)
      @undue_report.stub(:due?).and_return(false)

      subject.stub(:reports).and_return([@due_report, @undue_report])
      @due_report.stub(:config).and_return("I'm fine thank you")
    end

    describe '#run_reports!' do
      it 'should call Report#broadcast! for each configured and due report' do
        subject.reports.each { |t| t.should_receive(:due?).once }
        @due_report.should_receive(:broadcast!).once
        @undue_report.should_not_receive(:broadcast!)
        subject.run_reports!
      end
    end
  end

  describe 'receive_and_handle_messages' do
    before do
      @rq = Object.new
      subject.instance_variable_set(:@receive_queue, @rq)
    end

    it 'should handle a received message' do
      @rq.should_receive(:pop).exactly(2).times.and_return(:foo, nil)
      Watchy::Message.should_receive(:handle).once.with(:foo)
      subject.receive_and_handle_messages
    end
  end
end
