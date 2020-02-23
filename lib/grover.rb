# frozen_string_literal: true

require 'grover/version'

require 'grover/utils'
require 'active_support_ext/object/deep_dup' unless defined?(ActiveSupport)

require 'grover/html_preprocessor'
require 'grover/middleware'
require 'grover/configuration'
require 'grover/options_builder'

require 'nokogiri'
require 'schmooze'
require 'yaml'

#
# Grover interface for converting HTML to PDF
#
class Grover
  #
  # Processor helper class for calling out to Puppeteer NodeJS library
  #
  class Processor < Schmooze::Base
    dependencies puppeteer: 'puppeteer'

    def self.launch_params
      ENV['GROVER_NO_SANDBOX'] == 'true' ? "{args: ['--no-sandbox', '--disable-setuid-sandbox']}" : '{args: []}'
    end

    def self.convert_function(convert_action)
      <<~FUNCTION
        async (url_or_html, options) => {
          let browser;
          try {
            let launchParams = #{launch_params};

            // Configure puppeteer debugging options
            const debug = options.debug; delete options.debug;
            if (typeof debug === 'object' && !!debug) {
              if (debug.headless != undefined) { launchParams.headless = debug.headless; }
              if (debug.devtools != undefined) { launchParams.devtools = debug.devtools; }
            }

            // Configure additional launch arguments
            const args = options.launchArgs; delete options.launchArgs;
            if (Array.isArray(args)) {
              launchParams.args = launchParams.args.concat(args);
            }

            // Set executable path if given
            const executablePath = options.executablePath; delete options.executablePath;
            if (executablePath) {
              launchParams.executablePath = executablePath;
            }

            // Launch the browser and create a page
            browser = await puppeteer.launch(launchParams);
            const page = await browser.newPage();

            // Basic auth
            const username = options.username; delete options.username
            const password = options.password; delete options.password
            if (username != undefined && password != undefined) {
              await page.authenticate({ username, password });
            }

            // Set caching flag (if provided)
            const cache = options.cache; delete options.cache;
            if (cache != undefined) {
              await page.setCacheEnabled(cache);
            }

            // Setup timeout option (if provided)
            let request_options = {};
            const timeout = options.timeout; delete options.timeout;
            if (timeout != undefined) {
              request_options.timeout = timeout;
            }

            // Setup viewport options (if provided)
            const viewport = options.viewport; delete options.viewport;
            if (viewport != undefined) {
              await page.setViewport(viewport);
            }

            const waitUntil = options.waitUntil; delete options.waitUntil;
            if (url_or_html.match(/^http/i)) {
              // Request is for a URL, so request it
              request_options.waitUntil = waitUntil || 'networkidle2';
              await page.goto(url_or_html, request_options);
            } else {
              // Request is some HTML content. Use request interception to assign the body
              request_options.waitUntil = waitUntil || 'networkidle0';
              await page.setRequestInterception(true);
              page.once('request', request => {
                request.respond({ body: url_or_html });
                // Reset the request interception
                // (we only want to intercept the first request - ie our HTML)
                page.on('request', request => request.continue());
              });
              const displayUrl = options.displayUrl; delete options.displayUrl;
              await page.goto(displayUrl || 'http://example.com', request_options);
            }

            // If specified, emulate the media type
            const emulateMedia = options.emulateMedia; delete options.emulateMedia;
            if (emulateMedia != undefined) {
              if (typeof page.emulateMediaType == 'function') {
                await page.emulateMediaType(emulateMedia);
              } else {
                await page.emulateMedia(emulateMedia);
              }
            }

            // If specified, evaluate script on the page
            const executeScript = options.executeScript; delete options.executeScript;
            if (executeScript != undefined) {
              await page.evaluate(executeScript);
            }

            // If we're running puppeteer in headless mode, return the converted PDF
            if (debug == undefined || (typeof debug === 'object' && (debug.headless == undefined || debug.headless))) {
              return await page.#{convert_action}(options);
            }
          } finally {
            if (browser) {
              await browser.close();
            }
          }
        }
      FUNCTION
    end

    method :convert_pdf, convert_function('pdf')
    method :convert_screenshot, convert_function('screenshot')
  end
  private_constant :Processor

  DEFAULT_HEADER_TEMPLATE = "<div class='date text left'></div><div class='title text center'></div>"
  DEFAULT_FOOTER_TEMPLATE = <<~HTML
    <div class='url text left grow'></div>
    <div class='text right'><span class='pageNumber'></span>/<span class='totalPages'></span></div>
  HTML

  attr_reader :front_cover_path, :back_cover_path

  #
  # @param [String] url URL of the page to convert
  # @param [Hash] options Optional parameters to pass to PDF processor
  #   see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions
  #
  def initialize(url, options = {})
    @url = url
    @options = OptionsBuilder.new(options, url)
    @root_path = @options.delete 'root_path'
    @front_cover_path = @options.delete 'front_cover_path'
    @back_cover_path = @options.delete 'back_cover_path'
  end

  #
  # Request URL with provided options and create PDF
  #
  # @param [String] path Optional path to write the PDF to
  # @return [String] The resulting PDF data
  #
  def to_pdf(path = nil)
    result = processor.convert_pdf @url, normalized_options(path: path)
    return unless result

    result['data'].pack('C*')
  end

  #
  # Request URL with provided options and create screenshot
  #
  # @param [String] path Optional path to write the screenshot to
  # @param [String] format Optional format of the screenshot
  # @return [String] The resulting image data
  #
  def screenshot(path: nil, format: nil)
    options = normalized_options(path: path)
    options['type'] = format if format.is_a? ::String
    result = processor.convert_screenshot @url, options
    return unless result

    result['data'].pack('C*')
  end

  #
  # Request URL with provided options and create PNG
  #
  # @param [String] path Optional path to write the screenshot to
  # @return [String] The resulting PNG data
  #
  def to_png(path = nil)
    screenshot(path: path, format: 'png')
  end

  #
  # Request URL with provided options and create JPEG
  #
  # @param [String] path Optional path to write the screenshot to
  # @return [String] The resulting JPEG data
  #
  def to_jpeg(path = nil)
    screenshot(path: path, format: 'jpeg')
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

  #
  # Instance inspection
  #
  def inspect
    format(
      '#<%<class_name>s:0x%<object_id>p @url="%<url>s">',
      class_name: self.class.name,
      object_id: object_id,
      url: @url
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
    Processor.new(root_path)
  end

  def normalized_options(path:)
    normalized_options = Utils.normalize_object @options
    normalized_options['path'] = path if path.is_a? ::String
    normalized_options
  end
end
