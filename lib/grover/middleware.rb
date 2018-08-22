class Grover
  #
  # Rack middleware for catching PDF requests and returning the upstream HTML as a PDF
  #
  class Middleware
    def initialize(app)
      @app = app
      @render_pdf = false
    end

    def call(env)
      @request = Rack::Request.new(env)
      @render_pdf = false

      set_request_to_render_as_pdf(env) if render_as_pdf?
      status, headers, response = @app.call(env)

      if rendering_pdf? && headers['Content-Type'] =~ %r{text/html|application/xhtml\+xml}
        body = response.respond_to?(:body) ? response.body : response.join
        body = body.join if body.is_a?(Array)

        body = Grover.new(body).to_pdf
        response = [body]

        # Do not cache PDFs
        headers.delete 'ETag'
        headers.delete 'Cache-Control'

        headers['Content-Length'] = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
        headers['Content-Type'] = 'application/pdf'
      end

      [status, headers, response]
    end

    private

    def rendering_pdf?
      @render_pdf
    end

    def render_as_pdf?
      @request.path.end_with?('.pdf')
    end

    def set_request_to_render_as_pdf(env)
      @render_pdf = true
      env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
    end

    def concat(accepts, type)
      (accepts || '').split(',').unshift(type).compact.join(',')
    end
  end
end
