require_relative '../../spec_helper.rb'


describe Watchy::Config::ReportingConfigBuilder do
  describe '#report' do
    it 'should add a report to the collection' do
      class OtherTestReport; end
      OtherTestReport.should_receive(:new)
      subject.report(OtherTestReport)
    end
  end
end

