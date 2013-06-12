require 'simplecov'
SimpleCov.start

require(File.expand_path('../../lib/watchy', __FILE__))

RSpec.configure do |config|
  config.before(:each) do
    Settings[:loglevel] = 'unknown'
    Mysql2::Client.stub(:new).as_null_object
  end
end
