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
      }
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
    before { stub(Settings).as_null_object }

    it 'should bootstrap the databases' do 
      subject.should_receive(:bootstrap_databases!)
    end

    it 'should bootstrap the audit tables' do 
      subject.should_receive(:bootstrap_audit_tables!).once
    end

    after { subject.send(:initialize, 'tets') }
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

    describe '#enforce_audit_rules' do
      it 'should call Table#enforce_constraints for each audited table' do
        subject.tables.each { |t| t.should_receive(:enforce_audit_rules).once }
        subject.enforce_audit_rules
      end
    end
  end

  describe 'when working with reports' do
    before { subject.reports = [Object] }

    describe '#run_reports!' do
      it 'should call Report#run for each configured report' do
        subject.reports.each { |t| t.should_receive(:run).once }
        subject.run_reports!
      end
    end
  end
end
