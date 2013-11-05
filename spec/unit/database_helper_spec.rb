require_relative '../spec_helper.rb'


describe Watchy::DatabaseHelper do

  class Dummy; include Watchy::DatabaseHelper end

  subject { Dummy.new }

  describe '#connect_db' do
    it 'should instantiate a database client' do
      Mysql2::Client.should_receive(:new).once.with({ :reconnect => true, :foo => :bar })
      Watchy::DatabaseHelper.connect_db({ foo: :bar })
    end
  end

  describe '#db' do
    it 'should memoize the value returned by #connect_db' do
      Watchy::DatabaseHelper.should_receive(:connect_db).once.and_return('foo')
      2.times { subject.db }
    end
  end

  context 'when accessing settings' do
    before { Settings[:database] = {} }

    describe '#audit_db' do
      before { Settings[:database][:audit_schema] = 'yoodeloo' }

      it 'should return the elelement in the config hash' do
        subject.audit_db.should eql('yoodeloo')
      end
    end

    describe '#watched_db' do
      before { Settings[:database][:schema] = 'yoodeluu' }

      it 'should return the elelement in the config hash' do
        subject.watched_db.should eql('yoodeluu')
      end
    end
  end

end
