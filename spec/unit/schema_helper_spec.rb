require_relative '../spec_helper'

describe Watchy::SchemaHelper do

  class Dummy; include Watchy::SchemaHelper; end

  subject { Dummy.new }

  before do
    subject.stub(:watched_db).and_return('foo')
    subject.stub(:audit_db).and_return('bar')

    # For some weird reason, using a null object here generates errors
    subject.stub(:logger).and_return(Logger.new('/dev/null'))
  end

  describe '.bootstrap_databases!' do
    it 'should fail when the audited schema is missing' do
      subject.stub(:schema_exists?).and_return(false)
      expect { subject.bootstrap_databases! }.to raise_error("Audited DB 'foo' does not exist.")
    end

    it 'should succeed and create an audit schema' do
      subject.stub(:schema_exists?).and_return(true, false)

      subject.should_receive(:create_schema!).once.with('bar')
      subject.bootstrap_databases!
    end

    it 'should drop the existing audit schema if requested' do
      subject.stub(:config).and_return({
        database: {
          drop_audit_schema: true
        }
      })
      #Settings[:drop_audit_schema] = true
      subject.stub(:db).and_return(double(Object))
      subject.stub(:schema_exists?).and_return(true)

      subject.db.should_receive(:query).with('DROP DATABASE `bar`').once
      subject.should_receive(:create_schema!).once.with('bar')

      subject.bootstrap_databases!
    end
  end

  describe '#schema_exists?' do
    before do
      subject.stub(:db).and_return(double(Object))
      subject.db.stub(:query).and_return([{ 'Database' => 'foo' }])
    end

    it 'should correctly report an existing schema' do
      subject.schema_exists?('foo').should be_true
    end

    it 'should correctly report a missing schema' do
      subject.schema_exists?('bar').should be_false
    end
  end

  describe '#create_schema!' do
    it 'should fail if the schema already exists' do
      subject.stub(:schema_exists?).and_return(true)
      expect { subject.create_schema!('foo') }.to raise_error("Schema 'foo' already exists!")
    end

    it 'should create the database if does not exist yet' do
      subject.stub(:schema_exists?).and_return(false)
      subject.stub(:db).and_return(double(Object))
      subject.db.should_receive(:query).with("CREATE DATABASE `bar`").once
      subject.create_schema!('bar')
    end
  end
end
