# frozen_string_literal: true

require 'grover/version'

require 'grover/utils'
require 'active_support_ext/object/deep_dup' unless defined?(ActiveSupport)

require 'grover/errors'
require 'grover/html_preprocessor'
require 'grover/middleware'
require 'grover/configuration'
require 'grover/options_builder'
require 'grover/processor'

require 'nokogiri'
require 'yaml'

#
# Grover interface for converting HTML to PDF
#
class Grover
  DEFAULT_HEADER_TEMPLATE = "<div class='date text left'></div><div class='title text center'></div>"
  DEFAULT_FOOTER_TEMPLATE = <<~HTML
    <div class='url text left grow'></div>
    <div class='text right'><span class='pageNumber'></span>/<span class='totalPages'></span></div>
  HTML

  attr_reader :front_cover_path, :back_cover_path

  #
  # @param [String] root_path Path to the NodeJS package installation
  #
  def initialize(root_path: nil)
    @root_path = root_path
  end

  #
  # Request URL with provided options and create PDF
  #
  # @param [String] url URL of the page to convert
  # @param [String] path Optional path to write the PDF to
  # @param [Hash] options Optional parameters to pass to PDF processor
  #   see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions
  # @return [String] The resulting PDF data
  #
  def to_pdf(url, path: nil, **options)
    processor.convert :pdf, url, normalized_options(url: url, path: path, **options)
  end

  #
  # Request URL with provided options and render HTML
  #
  # @param [String] url URL of the page to convert
  # @param [Hash] options Optional parameters to pass to PDF processor
  #   see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions
  # @return [String] The resulting HTML string
  #
  def to_html(url, **options)
    processor.convert :content, url, normalized_options(url: url, path: nil, **options)
  end

  #
  # Request URL with provided options and create screenshot
  #
  # @param [String] url URL of the page to convert
  # @param [String] path Optional path to write the screenshot to
  # @param [String] format Optional format of the screenshot
  # @param [Hash] options Optional parameters to pass to PDF processor
  #   see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions
  # @return [String] The resulting image data
  #
  def screenshot(url, path: nil, format: nil, **options)
    options = normalized_options(url: url, path: path, **options)
    options['type'] = format if %w[png jpeg].include? format
    processor.convert :screenshot, url, options
  end

  #
  # Request URL with provided options and create PNG
  #
  # @param [String] url URL of the page to convert
  # @param [String] path Optional path to write the screenshot to
  # @param [Hash] options Optional parameters to pass to PDF processor
  #   see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions
  # @return [String] The resulting PNG data
  #
  def to_png(url, path: nil, **options)
    screenshot url, path: path, format: 'png', **options
  end

  #
  # Request URL with provided options and create JPEG
  #
  # @param [String] url URL of the page to convert
  # @param [String] path Optional path to write the screenshot to
  # @param [Hash] options Optional parameters to pass to PDF processor
  #   see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions
  # @return [String] The resulting JPEG data
  #
  def to_jpeg(url, path = nil, **options)
    screenshot url, path: path, format: 'jpeg', **options
  end

  #
  # Instance inspection
  #
  def inspect
    format(
      '#<%<class_name>s:0x%<object_id>p',
      class_name: self.class.name,
      object_id: object_id
    )
  end

  #
  # Configuration for the conversion
  #
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  private

  def root_path
    @root_path ||= Dir.pwd
  end

  def processor
    @processor ||= Processor.new(root_path)
  end

  def normalized_options(url:, path:, **options)
    parsed_options = OptionsBuilder.new(options, url)

    normalized_options = Utils.normalize_object parsed_options, excluding: ['extraHTTPHeaders']
    normalized_options['path'] = path if path.is_a? ::String
    normalized_options
  end
end
