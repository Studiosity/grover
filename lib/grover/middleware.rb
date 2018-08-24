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
      @render_pdf = false
    end

    def call(env)
      @request = Rack::Request.new(env)
      @render_pdf = false

      configure_env_for_pdf_request(env) if render_as_pdf?
      status, headers, response = @app.call(env)

      if rendering_pdf? && html_content?(headers)
        pdf = convert_to_pdf response
        response = [pdf]
        update_headers headers, pdf
      end

      [status, headers, response]
    end

    private

    PDF_REGEX = /\.pdf$/i

    def rendering_pdf?
      @render_pdf
    end

    def render_as_pdf?
      !@request.path.match(PDF_REGEX).nil?
    end

    def html_content?(headers)
      headers['Content-Type'] =~ %r{text/html|application/xhtml\+xml}
    end

    def convert_to_pdf(response)
      body = response.respond_to?(:body) ? response.body : response.join
      body = body.join if body.is_a?(Array)

      body = HTMLPreprocessor.process body, root_url, protocol
      Grover.new(body, display_url: request_url).to_pdf
    end

    def update_headers(headers, body)
      # Do not cache PDFs
      headers.delete 'ETag'
      headers.delete 'Cache-Control'

      headers['Content-Length'] = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
      headers['Content-Type'] = 'application/pdf'
    end

    def configure_env_for_pdf_request(env)
      @render_pdf = true

      env['PATH_INFO'] = path_without_extension
      env['REQUEST_URI'] = path_without_extension
      env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
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
      return @path_without_extension if defined? @path_without_extension
      path = @request.path.sub(PDF_REGEX, '')
      @path_without_extension = path.sub(@request.script_name, '')
    end

    def request_url
      "#{root_url.sub(%r{/\z}, '')}#{path_without_extension}"
    end

    def env
      @request.env
    end
  end
end
