require 'grover/version'

require 'grover/utils'
require 'grover/html_preprocessor'
require 'grover/middleware'
require 'grover/configuration'

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

    method :convert_pdf, Utils.squish(<<-FUNCTION)
      async (url, options) => {
        let browser;
        try {
          browser = await puppeteer.launch(#{launch_params});
          const page = await browser.newPage();
          if (url.match(/^http/i)) {
            await page.goto(url, { waitUntil: 'networkidle2' });
          } else {
            await page.goto(`data:text/html,${url}`, { waitUntil: 'networkidle0' });
          }

          const emulateMedia = options.emulateMedia; delete options.emulateMedia;
          if (emulateMedia) {
            await page.emulateMedia(emulateMedia);
          }

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

  #
  # @param [String] url URL of the page to convert
  # @param [Hash] options Optional parameters to pass to PDF processor
  #   see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions
  #
  def initialize(url, options = {})
    @url = url
    @options = Grover.configuration.options.merge options
    @root_path = @options.delete :root_path
  end

  #
  # Request URL with provided options and create PDF
  #
  # @param [String] path Optional path to write the PDF to
  # @return [String] The resulting PDF data
  #
  def to_pdf(path = nil)
    result = processor.convert_pdf @url, normalized_options(path)
    result['data'].pack('c*')
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

  def normalized_options(path)
    options = Utils.normalize_object @options
    options['path'] = path if path
    options
  end
end
