#require 'simplecov'
#SimpleCov.start

require 'rspec'

require(File.expand_path('../../lib/watchy', __FILE__))

RSpec.configure do |config|
  config.before(:each) do
    Settings[:logging][:level] = 'unknown'
  end

  config.mock_with :rspec
end
