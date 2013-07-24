require_relative '../spec_helper'

describe Watchy do
  describe '.boot' do
    before do
      @auditor = double(Watchy::Auditor).as_null_object
      Watchy::Auditor.should_receive(:new).and_return(@auditor)
    end

    it 'should run a Watchy::Auditor instance' do
      @auditor.should_receive :run!
      Watchy.boot!
    end
  end

  describe '.configure' do
    it 'should merge DSL gathered settings with the configliere hash' do
      Settings.should_receive(:defaults).once
      Watchy::Config::DSL.should_receive(:get_from).once.and_return({})
      Watchy.configure {}
    end
  end
end
