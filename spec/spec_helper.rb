require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'grover'

require 'active_support/core_ext/string/strip'
require 'rack/test'

RSpec.configure do |config|
  config.order = 'random'

  include Rack::Test::Methods
end
