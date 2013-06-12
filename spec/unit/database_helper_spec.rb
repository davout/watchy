require_relative '../spec_helper.rb'


describe Watchy::DatabaseHelper do
  describe '#connect_db' do

    class Dummy; include Watchy::DatabaseHelper end

    subject { Dummy.new }
    before { Dummy.any_instance.stub(:logger).and_return(mock(Object).as_null_object) }

    it 'should instantiate a database connection' do
      Mysql2::Client.should_receive(:new).once.with({ :foo => :bar })
      subject.connect_db({ :foo => :bar })
    end
  end
end
