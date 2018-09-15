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
      grover = create_grover_for_response(response)
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

    def fetch_cover_pdf(url)
      temp_env = env.deep_dup
      temp_env['PATH_INFO'], temp_env['QUERY_STRING'] = url.split '?'
      _, _, response = @app.call(env)
      response.close if response.respond_to? :close
      grover = create_grover_for_response response
      CombinePDF.parse grover.to_pdf
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
