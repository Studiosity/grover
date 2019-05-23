# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'grover/version'

Gem::Specification.new do |spec|
  spec.name        = 'grover'
  spec.version     = Grover::VERSION
  spec.authors     = ['Andrew Bromwich']
  spec.email       = %w[abromwich@studiosity.com]
  spec.description = 'Transform HTML into PDFs using Google Puppeteer/Chromium'
  spec.summary     = 'A Ruby gem to transform HTML into PDFs wrapper the NodeJS Google Puppeteer driver for Chromium'
  spec.homepage    = 'http://github.com/Studiosity/grover'
  spec.license     = 'MIT'

  spec.files         = `git ls-files lib`.split("\n")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_dependency 'combine_pdf', '~> 1.0'
  spec.add_dependency 'nokogiri', '~> 1.0'
  spec.add_dependency 'schmooze', '~> 0.2'

  spec.add_development_dependency 'pdf-reader', '~> 2.1'
  spec.add_development_dependency 'rack-test', '~> 1.1'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rubocop', '~> 0.53'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.28'
  spec.add_development_dependency 'simplecov', '~> 0.15'
end
