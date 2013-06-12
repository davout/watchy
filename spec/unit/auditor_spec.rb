require_relative '../spec_helper'

describe Watchy::Auditor do

  before do
    Watchy::Auditor.any_instance.stub(:bootstrap_databases!)
    Watchy::Auditor.any_instance.stub(:bootstrap_audit_tables!)
  end

  context '.new' do
    before do
      stub(Watchy).as_null_object
      Watchy.stub(:connection).and_return(:foo)
      stub(Settings).as_null_object
    end

    it 'should bootstrap the databases' do
      subject.should_receive(:bootstrap_databases!)
    end

    it 'should bootstrap the audit tables' do
      subject.should_receive(:bootstrap_audit_tables!).once
    end

    it 'should connect to the database' do
      Watchy.should_receive(:connection)
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
    end

    it 'should copy new rows to the audit database' do
      subject.should_receive :copy_new_rows
    end

    it 'should timestamp new rows with the current time' do
      subject.should_receive :stamp_new_rows
    end

    after do
      subject.send(:run!)
    end
  end
end
