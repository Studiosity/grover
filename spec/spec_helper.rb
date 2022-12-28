# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'grover'

require 'rack/test'
require 'stringio'
require 'pdf-reader'
require 'mini_magick'

RSpec.configure do |config|
  config.order = 'random'

  include Rack::Test::Methods
end

MiniMagick.validate_on_create = false

def puppeteer_version_on_or_after?(version)
  puppeteer_version = ENV.fetch('PUPPETEER_VERSION', '')
  puppeteer_version.empty? || Gem::Version.new(puppeteer_version) >= Gem::Version.new(version)
end
