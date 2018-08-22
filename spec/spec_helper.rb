require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'grover'

RSpec.configure do |config|
  config.order = 'random'
end
