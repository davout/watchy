require_relative '../spec_helper'

describe Watchy::Auditor do

  before do
    Watchy::Auditor.any_instance.stub(:bootstrap_databases!)
    Watchy::Auditor.any_instance.stub(:bootstrap_audit_tables!)
  end

  describe '.new' do
    before do
      stub(Settings).as_null_object
    end

    it 'should bootstrap the databases' do
      subject.should_receive(:bootstrap_databases!)
    end

    it 'should bootstrap the audit tables' do
      subject.should_receive(:bootstrap_audit_tables!).once
    end

    after do
      subject.send(:initialize)
    end
  end

  describe '#run' do
    before do
      subject.stub(:interrupted).and_return(false, true)
      subject.stub(:sleep_for)
      subject.stub(:stamp_new_rows)
      subject.stub(:copy_new_rows)
      subject.stub(:run_reports!)
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

  describe '#copy_new_rows' do
    before { subject.tables = [Object, Object, Object] }

    it 'should call Table#copy_new_rows for each audited table' do
      subject.tables.each { |t| t.should_receive(:copy_new_rows).once }
      subject.copy_new_rows
    end
  end

  describe '#stamp_new_rows' do
    before { subject.tables = [Object, Object, Object] }

    it 'should call Table#stamp_new_rows for each audited table' do
      subject.tables.each { |t| t.should_receive(:stamp_new_rows).once }
      subject.stamp_new_rows
    end
  end

  describe '#run_reports!' do
    before { subject.reports = [Object, Object, Object] }

    it 'should call Report#run for each configured report' do
      subject.reports.each { |t| t.should_receive(:run).once }
      subject.run_reports!
    end
  end
end
