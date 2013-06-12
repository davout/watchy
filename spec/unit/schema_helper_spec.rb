require_relative '../spec_helper'

describe Watchy::SchemaHelper do

    class Dummy; include Watchy::SchemaHelper; end

  subject { Dummy.new }
  before { subject.stub(:watched_db).and_return('foo') }

  describe '.bootstrap_databases!' do
    it 'should fail when the audited schema is missing' do
      subject.stub(:schema_exists?).and_return(false)
      expect { subject.bootstrap_databases! }.to raise_error('Audited DB foo does not exist.')
    end
  end

  describe '#schema_exists?' do
    before do
      mock_connection = mock(Object).as_null_object
      subject.stub(:connection).and_return(mock_connection)
      mock_connection.stub(:query).and_return([{ 'Database' => 'foo' }])
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
      pending
    end

  end
end
