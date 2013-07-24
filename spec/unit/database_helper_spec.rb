require_relative '../spec_helper.rb'


describe Watchy::DatabaseHelper do

  class Dummy; include Watchy::DatabaseHelper end

  subject { Dummy.new }

  describe '#connect_db' do
    it 'should instantiate a database client' do
      Mysql2::Client.should_receive(:new).once.with({ :foo => :bar })
      Watchy::DatabaseHelper.connect_db({ foo: :bar })
    end
  end

  describe '#db' do
    before { subject.stub(:config).and_return({}) }

    it 'should memoize the value returned by #connect_db' do
      Watchy::DatabaseHelper.should_receive(:connect_db).once.and_return('foo')
      2.times { subject.db }
    end
  end
end
