require(File.expand_path('../../lib/watchy', __FILE__))

RSpec.configure do |config|
  config.before(:each) do
    Watchy.logger.level = Logger::Severity::UNKNOWN
    Mysql2::Client.stub(:new).as_null_object
  end
end
