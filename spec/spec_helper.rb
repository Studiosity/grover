# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'grover'

require 'rack/test'
require 'stringio'
require 'pdf-reader'
require 'mini_magick'
require_relative 'support/test_server'

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run_excluding remote_browser: true

  config.before(:suite) do
    TestServer.start
  end

  config.after(:suite) do
    TestServer.stop
  end

  include Rack::Test::Methods
end

def fixture_path(file)
  File.join(File.expand_path(__dir__), 'fixtures', file)
end

def puppeteer_version_on_or_after?(version)
  puppeteer_version.empty? || Gem::Version.new(puppeteer_version) >= Gem::Version.new(version)
end

def puppeteer_version_on_or_before?(version)
  puppeteer_version.empty? || Gem::Version.new(puppeteer_version) <= Gem::Version.new(version)
end

def puppeteer_version
  @puppeteer_version ||=
    ENV.fetch('PUPPETEER_VERSION', nil) || `npm list puppeteer`[/puppeteer@(\d{1,3}(.\d{1,3}){0,2})\n/, 1]
end

def linux_system?
  uname = `uname -s`
  uname.start_with? 'Linux'
end
