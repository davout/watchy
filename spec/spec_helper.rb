require 'simplecov'
require(File.expand_path('../../lib/watchy', __FILE__))

SimpleCov.start do
  add_filter "colored_logger"
end

RSpec.configure do |config|
  config.before(:each) do
    Settings[:logging][:level] = 'unknown'
  end

  config.mock_with :rspec
end
