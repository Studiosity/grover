# frozen_string_literal: true

require 'combine_pdf'

class Grover
  #
  # Rack middleware for catching PDF requests and returning the upstream HTML as a PDF
  #
  # Much of this code was sourced from the PDFKit project
  # @see https://github.com/pdfkit/pdfkit
  #
  class Middleware
    def initialize(app)
      @app = app
      @pdf_request = false
      @png_request = false
      @jpeg_request = false
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      @request = Rack::Request.new(env)
      identify_request_type

      configure_env_for_grover_request(env) if grover_request?
      status, headers, response = @app.call(env)
      response = update_response response, headers if grover_request? && html_content?(headers)

      [status, headers, response]
    end

    private

    PDF_REGEX = /\.pdf$/i.freeze
    PNG_REGEX = /\.png$/i.freeze
    JPEG_REGEX = /\.jpe?g$/i.freeze

    attr_reader :pdf_request, :png_request, :jpeg_request

    def identify_request_type
      @pdf_request = Grover.configuration.use_pdf_middleware && path_matches?(PDF_REGEX)
      @png_request = Grover.configuration.use_png_middleware && path_matches?(PNG_REGEX)
      @jpeg_request = Grover.configuration.use_jpeg_middleware && path_matches?(JPEG_REGEX)
    end

    def path_matches?(regex)
      !@request.path.match(regex).nil?
    end

    def grover_request?
      (pdf_request || png_request || jpeg_request) && !ignore_request?
    end

    def ignore_request?
      ignore_path = Grover.configuration.ignore_path
      case ignore_path
      when String then @request.path.start_with? ignore_path
      when Regexp then !ignore_path.match(@request.path).nil?
      when Proc then ignore_path.call @request.path
      end
    end

    def html_content?(headers)
      headers['Content-Type'] =~ %r{text/html|application/xhtml\+xml}
    end

    def update_response(response, headers)
      body, content_type = convert_response response
      assign_headers headers, body, content_type
      [body]
    end

    def convert_response(response)
      grover = create_grover_for_response(response)

      if pdf_request
        [convert_to_pdf(grover), 'application/pdf']
      elsif png_request
        [grover.to_png, 'image/png']
      elsif jpeg_request
        [grover.to_jpeg, 'image/jpeg']
      end
    end

    def convert_to_pdf(grover)
      if grover.show_front_cover? || grover.show_back_cover?
        add_cover_content grover
      else
        grover.to_pdf
      end
    end

    def create_grover_for_response(response)
      body = response.respond_to?(:body) ? response.body : response.join
      body = body.join if body.is_a?(Array)

      body = HTMLPreprocessor.process body, root_url, protocol
      Grover.new(body, display_url: request_url)
    end

    def add_cover_content(grover)
      pdf = CombinePDF.parse grover.to_pdf
      pdf >> fetch_cover_pdf(grover.front_cover_path) if grover.show_front_cover?
      pdf << fetch_cover_pdf(grover.back_cover_path) if grover.show_back_cover?
      pdf.to_pdf
    end

    def fetch_cover_pdf(path)
      temp_env = env.deep_dup
      temp_env['PATH_INFO'], temp_env['QUERY_STRING'] = path.split '?'
      _, _, response = @app.call(temp_env)
      response.close if response.respond_to? :close
      grover = create_grover_for_response response
      CombinePDF.parse grover.to_pdf
    end

    def assign_headers(headers, body, content_type)
      # Do not cache results
      headers.delete 'ETag'
      headers.delete 'Cache-Control'

      headers['Content-Length'] = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
      headers['Content-Type'] = content_type
    end

    def configure_env_for_grover_request(env)
      env['PATH_INFO'] = env['REQUEST_URI'] = path_without_extension
      env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
      env['Rack-Middleware-Grover'] = 'true'
    end

    def concat(accepts, type)
      (accepts || '').split(',').unshift(type).compact.join(',')
    end

    def root_url
      @root_url ||= "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/"
    end

    def protocol
      env['rack.url_scheme']
    end

    def path_without_extension
      @request.path.sub(request_regex, '').sub(@request.script_name, '')
    end

    def request_regex
      if pdf_request
        PDF_REGEX
      elsif png_request
        PNG_REGEX
      elsif jpeg_request
        JPEG_REGEX
      end
    end

    def request_url
      "#{root_url.sub(%r{/\z}, '')}#{path_without_extension}"
    end

    def env
      @request.env
    end
  end
end
