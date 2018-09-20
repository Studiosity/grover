require 'grover/version'

require 'grover/utils'
require 'active_support_ext/object/deep_dup'

require 'grover/html_preprocessor'
require 'grover/middleware'
require 'grover/configuration'

require 'nokogiri'
require 'schmooze'

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
      ENV['CI'] == 'true' ? "{args: ['--no-sandbox', '--disable-setuid-sandbox']}" : ''
    end

    method :convert_pdf, <<-FUNCTION
      async (url_or_html, options) => {
        let browser;
        try {
          // Launch the browser and create a page
          browser = await puppeteer.launch(#{launch_params});
          const page = await browser.newPage();

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

          if (url_or_html.match(/^http/i)) {
            // Request is for a URL, so request it 
            request_options.waitUntil = 'networkidle2';
            await page.goto(url_or_html, request_options);
          } else {
            // Request is some HTML content. Use request interception to assign the body
            request_options.waitUntil = 'networkidle0';
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
            await page.emulateMedia(emulateMedia);
          }

          // Return the converted PDF
          return await page.pdf(options);
        } finally {
          if (browser) {
            await browser.close();
          }
        }
      }
    FUNCTION
  end
  private_constant :Processor

  DEFAULT_HEADER_TEMPLATE = "<div class='date text left'></div><div class='title text center'></div>".freeze
  DEFAULT_FOOTER_TEMPLATE = Utils.strip_heredoc(<<-HTML).freeze
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
    @options = combine_options options

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
    normalized_options = Utils.normalize_object @options
    normalized_options['path'] = path if path.is_a? ::String
    result = processor.convert_pdf @url, normalized_options
    result['data'].pack('c*')
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

  def combine_options(options)
    combined = Utils.deep_stringify_keys Grover.configuration.options
    Utils.deep_merge! combined, Utils.deep_stringify_keys(options)
    Utils.deep_merge! combined, meta_options unless url_source?

    fix_boolean_options! combined
    fix_numeric_options! combined

    combined
  end

  #
  # Extract out options from meta tags in the source - based on code from PDFKit project
  #
  def meta_options
    meta_opts = {}

    meta_tags.each do |meta|
      tag_name = meta['name'] && meta['name'][/#{Grover.configuration.meta_tag_prefix}([a-z_-]+)/, 1]
      next unless tag_name

      Utils.deep_assign meta_opts, tag_name.split('-'), meta['content']
    end

    meta_opts
  end

  def meta_tags
    Nokogiri::HTML(@url).xpath('//meta')
  end

  def url_source?
    @url.match(/^http/i)
  end

  def fix_boolean_options!(options)
    %w[display_header_footer print_background landscape prefer_css_page_size].each do |opt|
      next unless options.key? opt

      options[opt] = !FALSE_VALUES.include?(options[opt])
    end
  end

  FALSE_VALUES = [nil, false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].freeze

  def fix_numeric_options!(options)
    return unless options.key? 'scale'

    options['scale'] = options['scale'].to_f
  end
end
