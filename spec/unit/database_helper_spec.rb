require_relative '../spec_helper.rb'


describe Watchy::DatabaseHelper do

  class Dummy; include Watchy::DatabaseHelper end

  subject { Dummy.new }
  before { Dummy.any_instance.stub(:logger).and_return(mock(Object).as_null_object) }

  describe '#connect_db' do
    it 'should instantiate a database connection' do
      Mysql2::Client.should_receive(:new).once.with({ :foo => :bar })
      subject.connect_db({ :foo => :bar })
    end
  end

  describe '#connection' do
    before { subject.stub(:config).and_return({}) }

    it 'should memoize the value returned by #connect_db' do
      subject.should_receive(:connect_db).once.and_return('foo')
      2.times { subject.connection }
    end
  end
end
