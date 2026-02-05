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
  # @param [String] uri URI of the page to convert
  # @param [Hash] options Optional parameters to pass to PDF processor
  #   see https://github.com/puppeteer/puppeteer/blob/main/docs/api/puppeteer.pdfoptions.md
  #   and https://github.com/puppeteer/puppeteer/blob/main/docs/api/puppeteer.screenshotoptions.md
  #
  def initialize(uri, **options)
    @uri = uri.to_s
    @options = OptionsBuilder.new(options, @uri)
    @root_path = @options.delete 'root_path'
    @front_cover_path = @options.delete 'front_cover_path'
    @back_cover_path = @options.delete 'back_cover_path'
  end

  #
  # Request URI with provided options and create PDF
  #
  # @param [String] path Optional path to write the PDF to
  # @return [String] The resulting PDF data
  #
  def to_pdf(path = nil)
    @processor = nil # Flush out the processor from any previous use
    processor.convert :pdf, @uri, normalized_options(path: path)
  end

  #
  # Request URI with provided options and render HTML
  #
  # @return [String] The resulting HTML string
  #
  def to_html
    @processor = nil # Flush out the processor from any previous use
    processor.convert :content, @uri, normalized_options(path: nil)
  end

  #
  # Request URI with provided options and create screenshot
  #
  # @param [String] path Optional path to write the screenshot to
  # @param [String] format Optional format of the screenshot
  # @return [String] The resulting image data
  #
  def screenshot(path: nil, format: nil)
    @processor = nil # Flush out the processor from any previous use
    options = normalized_options(path: path)
    options['type'] = format if %w[png jpeg].include? format
    processor.convert :screenshot, @uri, options
  end

  #
  # Request URI with provided options and create PNG
  #
  # @param [String] path Optional path to write the screenshot to
  # @return [String] The resulting PNG data
  #
  def to_png(path = nil)
    screenshot path: path, format: 'png'
  end

  #
  # Request URI with provided options and create JPEG
  #
  # @param [String] path Optional path to write the screenshot to
  # @return [String] The resulting JPEG data
  #
  def to_jpeg(path = nil)
    screenshot path: path, format: 'jpeg'
  end

  #
  # Returns whether a front cover (request) path has been specified in the options
  #
  # @return [Boolean] Front cover path is configured
  #
  def show_front_cover?
    front_cover_path.is_a?(::String) && front_cover_path.start_with?('/')
  end

  #
  # Returns whether a back cover (request) path has been specified in the options
  #
  # @return [Boolean] Back cover path is configured
  #
  def show_back_cover?
    back_cover_path.is_a?(::String) && back_cover_path.start_with?('/')
  end

  def debug_output
    processor.debug_output
  end

  #
  # Instance inspection
  #
  def inspect
    format(
      '#<%<class_name>s:0x%<object_id>p @uri="%<uri>s">',
      class_name: self.class.name,
      object_id: object_id,
      uri: @uri
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

  def normalized_options(path:)
    normalized_options = Utils.normalize_object @options, excluding: ['extraHTTPHeaders']
    normalized_options['path'] = path if path.is_a? ::String
    normalized_options['allowFileUri'] = Grover.configuration.allow_file_uris == true
    normalized_options['allowLocalNetworkAccess'] = Grover.configuration.allow_local_network_access == true
    normalized_options
  end
end
