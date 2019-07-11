# frozen_string_literal: true

class Grover
  #
  # Configuration of the options for Grover HTML to PDF conversion
  #
  class Configuration
    attr_accessor :options, :meta_tag_prefix, :use_pdf_middleware, :use_png_middleware, :use_jpeg_middleware

    def initialize
      @options = {}
      @meta_tag_prefix = 'grover-'
      @use_pdf_middleware = true
      @use_png_middleware = false
      @use_jpeg_middleware = false
    end
  end
end
