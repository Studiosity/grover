require 'grover/version'

require 'grover/utils'
require 'grover/processor'
require 'grover/html_preprocessor'
require 'grover/middleware'

#
# Grover interface for converting HTML to PDF
#
class Grover
  #
  # @param [String] url URL of the page to convert
  # @param [Hash] options Optional parameters to pass to PDF processor
  #   see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions
  #
  def initialize(url, options = {})
    @url = url
    @root_path = options.delete :root_path
    @options = options
  end

  #
  # Request URL with provided options and create PDF
  #
  # @param [String] path Optional path to write the PDF to
  # @return [Array<Integer>] Byte array of the resulting PDF
  #
  def to_pdf(path = nil)
    options = @options.dup
    options[:path] = path if path
    result = processor.convert_pdf @url, options
    result['data'].pack('c*')
  end

  def inspect
    format(
      '#<%<class_name>s:0x%<object_id>p @url="%<url>s">',
      class_name: self.class.name,
      object_id: object_id,
      url: @url
    )
  end

  private

  def root_path
    @root_path ||= Dir.pwd
  end

  def processor
    Grover::Processor.new(root_path)
  end
end
