# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'grover/version'

Gem::Specification.new do |spec|
  spec.name        = 'grover'
  spec.version     = Grover::VERSION
  spec.authors     = ['Andrew Bromwich']
  spec.email       = %w[abromwich@studiosity.com]
  spec.description = 'Transform HTML into PDF/PNG/JPEG using Google Puppeteer/Chromium'
  spec.summary     = <<~SUMMARY.delete("\n")
    A Ruby gem to transform HTML into PDF, PNG or JPEG by wrapping the NodeJS Google Puppeteer driver for Chromium
  SUMMARY
  spec.homepage    = 'https://github.com/Studiosity/grover'
  spec.license     = 'MIT'
  spec.required_ruby_version = ['>= 2.6.0', '< 3.2.0']

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = `git ls-files lib`.split("\n") + ['LICENSE']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_dependency 'combine_pdf', '~> 1.0'
  spec.add_dependency 'nokogiri', '~> 1.0'

  spec.add_development_dependency 'mini_magick', '~> 4.9'
  spec.add_development_dependency 'pdf-reader', '~> 2.2'
  spec.add_development_dependency 'rack-test', '~> 1.1'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rubocop', '~> 0.72'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.33'
  # Limit simplecov to 0.17.x due to https://github.com/codeclimate/test-reporter/issues/413
  spec.add_development_dependency 'simplecov', '~> 0.17', '< 0.18'
end
