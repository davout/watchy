require_relative '../spec_helper'

describe Watchy do
  describe '.boot' do
    before do
      @auditor = mock(Watchy::Auditor).as_null_object
      Watchy::Auditor.should_receive(:new).and_return(@auditor)
    end

    it 'should run a Watchy::Auditor instance' do
      @auditor.should_receive :run!
      Watchy.boot!
    end
  end
end
