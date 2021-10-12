# frozen_string_literal: true

require 'spec_helper'

describe Grover::Middleware do
  subject(:mock_app) do
    builder = Rack::Builder.new
    builder.use described_class
    builder.run downstream
    builder.to_app
  end

  let(:downstream) do
    lambda do |env|
      # take a reference to the original env so we can test the final state
      @response_env = env
      # take a copy of the env so we can test the downstream (current) state
      @request_env = env.deep_dup
      response_size = 0
      response.each { |part| response_size += part.length }
      [200, headers.merge('Content-Length' => response_size.to_s), response]
    end
  end

  let(:app) { Rack::Lint.new(subject) }
  let(:headers) do
    {
      'Content-Type' => 'text/html',
      'ETag' => 'foo',
      'Cache-Control' => 'max-age=2592000, public'
    }
  end
  let(:response) { ['Grover McGroveryface'] }

  attr_reader :request_env, :response_env

  describe '#call' do
    describe 'response content type' do
      context 'when requesting a PDF' do
        it 'returns PDF content type' do
          get 'http://www.example.org/test.pdf'
          expect(last_response.headers['Content-Type']).to eq 'application/pdf'
          response_size = Grover.new('Grover McGroveryface').to_pdf.bytesize
          expect(last_response.body.bytesize).to eq response_size
          expect(last_response.headers['Content-Length']).to eq response_size.to_s
        end

        it 'matches PDF case insensitive' do
          get 'http://www.example.org/test.PDF'
          expect(last_response.headers['Content-Type']).to eq 'application/pdf'
          response_size = Grover.new('Grover McGroveryface').to_pdf.bytesize
          expect(last_response.body.bytesize).to eq response_size
          expect(last_response.headers['Content-Length']).to eq response_size.to_s
        end
      end

      context 'when requesting a PNG' do
        before { allow(Grover.configuration).to receive(:use_png_middleware).and_return true }

        it 'returns PNG content type' do
          get 'http://www.example.org/test.png'
          expect(last_response.headers['Content-Type']).to eq 'image/png'
          response_size = Grover.new('Grover McGroveryface').to_png.bytesize
          expect(last_response.body.bytesize).to eq response_size
          expect(last_response.headers['Content-Length']).to eq response_size.to_s
        end

        it 'matches PNG case insensitive' do
          get 'http://www.example.org/test.PNG'
          expect(last_response.headers['Content-Type']).to eq 'image/png'
          response_size = Grover.new('Grover McGroveryface').to_png.bytesize
          expect(last_response.body.bytesize).to eq response_size
          expect(last_response.headers['Content-Length']).to eq response_size.to_s
        end
      end

      context 'when requesting a JPEG' do
        before { allow(Grover.configuration).to receive(:use_jpeg_middleware).and_return true }

        it 'returns JPEG content type' do
          get 'http://www.example.org/test.jpeg'
          expect(last_response.headers['Content-Type']).to eq 'image/jpeg'
          response_size = Grover.new('Grover McGroveryface').to_jpeg.bytesize
          expect(last_response.body.bytesize).to eq response_size
          expect(last_response.headers['Content-Length']).to eq response_size.to_s
        end

        it 'matches JPEG case insensitive' do
          get 'http://www.example.org/test.JPEG'
          expect(last_response.headers['Content-Type']).to eq 'image/jpeg'
          response_size = Grover.new('Grover McGroveryface').to_jpeg.bytesize
          expect(last_response.body.bytesize).to eq response_size
          expect(last_response.headers['Content-Length']).to eq response_size.to_s
        end

        it 'matches JPG case insensitive' do
          get 'http://www.example.org/test.JPG'
          expect(last_response.headers['Content-Type']).to eq 'image/jpeg'
          response_size = Grover.new('Grover McGroveryface').to_jpeg.bytesize
          expect(last_response.body.bytesize).to eq response_size
          expect(last_response.headers['Content-Length']).to eq response_size.to_s
        end
      end

      context 'when request doesnt have an extension' do
        it 'returns the downstream content type' do
          get 'http://www.example.org/test'
          expect(last_response.headers['Content-Type']).to eq 'text/html'
          expect(last_response.body).to eq 'Grover McGroveryface'
          expect(last_response.headers['Content-Length']).to eq '20'
        end
      end

      context 'when request has a non-PDF/PNG/JPEG extension' do
        it 'returns the downstream content type' do
          get 'http://www.example.org/test.html'
          expect(last_response.headers['Content-Type']).to eq 'text/html'
          expect(last_response.body).to eq 'Grover McGroveryface'
          expect(last_response.headers['Content-Length']).to eq '20'
        end
      end
    end

    describe 'rack environment' do
      context 'when requesting a PDF' do
        it 'removes PDF extension from request PATH_INFO and REQUEST_URI' do
          get 'http://www.example.org/test.pdf'
          # env state sent to downstream middleware
          expect(request_env['PATH_INFO']).to eq '/test'
          expect(request_env['REQUEST_URI']).to eq 'http://www.example.org/test'
          expect(request_env['Rack-Middleware-Grover']).to eq 'true'

          # env state bubbling back up
          expect(response_env['PATH_INFO']).to eq '/test.pdf'
          expect(response_env['REQUEST_URI']).to eq 'http://www.example.org/test.pdf'
          expect(response_env['Rack-Middleware-Grover']).to eq 'true'
        end

        context 'when request has inline parameters' do
          it 'includes the parameters in the request URI' do
            get 'http://www.example.org/test.pdf?def=123&abc=456'
            # env state sent to downstream middleware
            expect(request_env['PATH_INFO']).to eq '/test'
            expect(request_env['REQUEST_URI']).to eq 'http://www.example.org/test?def=123&abc=456'
            expect(request_env['Rack-Middleware-Grover']).to eq 'true'

            # env state bubbling back up
            expect(response_env['PATH_INFO']).to eq '/test.pdf'
            expect(response_env['REQUEST_URI']).to eq 'http://www.example.org/test.pdf?def=123&abc=456'
            expect(response_env['Rack-Middleware-Grover']).to eq 'true'
          end
        end

        context 'when app configuration has PDF middleware disabled' do
          before { allow(Grover.configuration).to receive(:use_pdf_middleware).and_return false }

          it 'doesnt assign path environment variables' do
            get 'http://www.example.org/test.pdf'
            # env state sent to downstream middleware
            expect(request_env['PATH_INFO']).to eq '/test.pdf'
            expect(request_env).not_to have_key 'REQUEST_URI'
            expect(request_env).not_to have_key 'Rack-Middleware-Grover'

            # env state bubbling back up
            expect(response_env['PATH_INFO']).to eq '/test.pdf'
            expect(response_env).not_to have_key 'REQUEST_URI'
            expect(response_env).not_to have_key 'Rack-Middleware-Grover'
          end
        end
      end

      context 'when requesting a PNG' do
        it 'doesnt assign path environment variables' do
          get 'http://www.example.org/test.png'
          # env state sent to downstream middleware
          expect(request_env['PATH_INFO']).to eq '/test.png'
          expect(request_env).not_to have_key 'REQUEST_URI'
          expect(request_env).not_to have_key 'Rack-Middleware-Grover'

          # env state bubbling back up
          expect(response_env['PATH_INFO']).to eq '/test.png'
          expect(response_env).not_to have_key 'REQUEST_URI'
          expect(response_env).not_to have_key 'Rack-Middleware-Grover'
        end

        context 'when app configuration has PNG middleware enabled' do
          before { allow(Grover.configuration).to receive(:use_png_middleware).and_return true }

          it 'removes PNG extension from request PATH_INFO and REQUEST_URI' do
            get 'http://www.example.org/test.png'
            # env state sent to downstream middleware
            expect(request_env['PATH_INFO']).to eq '/test'
            expect(request_env['REQUEST_URI']).to eq 'http://www.example.org/test'
            expect(request_env['Rack-Middleware-Grover']).to eq 'true'

            # env state bubbling back up
            expect(response_env['PATH_INFO']).to eq '/test.png'
            expect(response_env['REQUEST_URI']).to eq 'http://www.example.org/test.png'
            expect(response_env['Rack-Middleware-Grover']).to eq 'true'
          end
        end
      end

      context 'when requesting a JPEG' do
        it 'doesnt assign path environment variables for JPEG' do
          get 'http://www.example.org/test.jpeg'
          # env state sent to downstream middleware
          expect(request_env['PATH_INFO']).to eq '/test.jpeg'
          expect(request_env).not_to have_key 'REQUEST_URI'
          expect(request_env).not_to have_key 'Rack-Middleware-Grover'

          # env state bubbling back up
          expect(response_env['PATH_INFO']).to eq '/test.jpeg'
          expect(response_env).not_to have_key 'REQUEST_URI'
          expect(response_env).not_to have_key 'Rack-Middleware-Grover'
        end

        it 'doesnt assign path environment variables for JPG' do
          get 'http://www.example.org/test.jpg'
          # env state sent to downstream middleware
          expect(request_env['PATH_INFO']).to eq '/test.jpg'
          expect(request_env).not_to have_key 'REQUEST_URI'
          expect(request_env).not_to have_key 'Rack-Middleware-Grover'

          # env state bubbling back up
          expect(response_env['PATH_INFO']).to eq '/test.jpg'
          expect(response_env).not_to have_key 'REQUEST_URI'
          expect(response_env).not_to have_key 'Rack-Middleware-Grover'
        end

        context 'when app configuration has JPEG middleware enabled' do
          before { allow(Grover.configuration).to receive(:use_jpeg_middleware).and_return true }

          it 'removes JPEG extension from request PATH_INFO and REQUEST_URI' do
            get 'http://www.example.org/test.jpeg'
            # env state sent to downstream middleware
            expect(request_env['PATH_INFO']).to eq '/test'
            expect(request_env['REQUEST_URI']).to eq 'http://www.example.org/test'
            expect(request_env['Rack-Middleware-Grover']).to eq 'true'

            # env state bubbling back up
            expect(response_env['PATH_INFO']).to eq '/test.jpeg'
            expect(response_env['REQUEST_URI']).to eq 'http://www.example.org/test.jpeg'
            expect(response_env['Rack-Middleware-Grover']).to eq 'true'
          end

          it 'removes JPG extension from request PATH_INFO and REQUEST_URI' do
            get 'http://www.example.org/test.jpg'
            # env state sent to downstream middleware
            expect(request_env['PATH_INFO']).to eq '/test'
            expect(request_env['REQUEST_URI']).to eq 'http://www.example.org/test'
            expect(request_env['Rack-Middleware-Grover']).to eq 'true'

            # env state bubbling back up
            expect(response_env['PATH_INFO']).to eq '/test.jpg'
            expect(response_env['REQUEST_URI']).to eq 'http://www.example.org/test.jpg'
            expect(response_env['Rack-Middleware-Grover']).to eq 'true'
          end
        end
      end

      context 'when not requesting a PDF/PNG or JPEG' do
        it 'keeps the original PATH_INFO and not change to REQUEST_URI' do
          get 'http://www.example.org/test.html'
          # env state sent to downstream middleware
          expect(request_env['PATH_INFO']).to eq '/test.html'
          expect(request_env).not_to have_key 'REQUEST_URI'
          expect(request_env).not_to have_key 'Rack-Middleware-Grover'

          # env state bubbling back up
          expect(response_env['PATH_INFO']).to eq '/test.html'
          expect(response_env).not_to have_key 'REQUEST_URI'
          expect(response_env).not_to have_key 'Rack-Middleware-Grover'
        end
      end
    end

    describe 'caching' do
      context 'when requesting a PDF' do
        it 'deletes the cache headers' do
          get 'http://www.example.org/test.pdf'
          expect(last_response.headers).not_to have_key 'ETag'
          expect(last_response.headers).not_to have_key 'Cache-Control'
        end

        context 'when app configuration has PDF middleware disabled' do
          before { allow(Grover.configuration).to receive(:use_pdf_middleware).and_return false }

          it 'returns the cache headers' do
            get 'http://www.example.org/test.pdf'
            expect(last_response.headers['ETag']).to eq 'foo'
            expect(last_response.headers['Cache-Control']).to eq 'max-age=2592000, public'
          end
        end
      end

      context 'when requesting a PNG' do
        it 'returns the cache headers' do
          get 'http://www.example.org/test.png'
          expect(last_response.headers['ETag']).to eq 'foo'
          expect(last_response.headers['Cache-Control']).to eq 'max-age=2592000, public'
        end

        context 'when app configuration has PNG middleware enabled' do
          before { allow(Grover.configuration).to receive(:use_png_middleware).and_return true }

          it 'deletes the cache headers' do
            get 'http://www.example.org/test.png'
            expect(last_response.headers).not_to have_key 'ETag'
            expect(last_response.headers).not_to have_key 'Cache-Control'
          end
        end
      end

      context 'when requesting a JPEG' do
        it 'returns the cache headers' do
          get 'http://www.example.org/test.jpeg'
          expect(last_response.headers['ETag']).to eq 'foo'
          expect(last_response.headers['Cache-Control']).to eq 'max-age=2592000, public'
        end

        context 'when app configuration has JPEG middleware enabled' do
          before { allow(Grover.configuration).to receive(:use_jpeg_middleware).and_return true }

          it 'deletes the cache headers for JPEG' do
            get 'http://www.example.org/test.jpeg'
            expect(last_response.headers).not_to have_key 'ETag'
            expect(last_response.headers).not_to have_key 'Cache-Control'
          end

          it 'deletes the cache headers for JPG' do
            get 'http://www.example.org/test.jpg'
            expect(last_response.headers).not_to have_key 'ETag'
            expect(last_response.headers).not_to have_key 'Cache-Control'
          end
        end
      end

      context 'when not requesting a PDF, PNG or JPEG' do
        it 'returns the cache headers' do
          get 'http://www.example.org/test'
          expect(last_response.headers['ETag']).to eq 'foo'
          expect(last_response.headers['Cache-Control']).to eq 'max-age=2592000, public'
        end
      end
    end

    describe 'response' do
      context 'when response is a Rack::Response' do
        let(:response) { Rack::Response.new(['Rackalicious'], 200) }

        it 'returns response as PDF' do
          get 'http://www.example.org/test.pdf'
          expect(last_response.headers['Content-Type']).to eq 'application/pdf'
          expect(last_response.body.bytesize).to eq Grover.new('Rackalicious').to_pdf.bytesize
        end

        context 'when app configuration has PDF middleware disabled' do
          before { allow(Grover.configuration).to receive(:use_pdf_middleware).and_return false }

          it 'returns response as text (original)' do
            get 'http://www.example.org/test.pdf'
            expect(last_response.headers['Content-Type']).to eq 'text/html'
            expect(last_response.body).to eq 'Rackalicious'
          end
        end

        it 'returns PNG response as text (original)' do
          get 'http://www.example.org/test.png'
          expect(last_response.headers['Content-Type']).to eq 'text/html'
          expect(last_response.body).to eq 'Rackalicious'
        end

        context 'when app configuration has PNG middleware enabled' do
          before { allow(Grover.configuration).to receive(:use_png_middleware).and_return true }

          it 'returns response as PNG' do
            get 'http://www.example.org/test.png'
            expect(last_response.headers['Content-Type']).to eq 'image/png'
            expect(last_response.body.bytesize).to eq Grover.new('Rackalicious').to_png.bytesize
          end
        end

        it 'returns JPEG response as text (original)' do
          get 'http://www.example.org/test.jpeg'
          expect(last_response.headers['Content-Type']).to eq 'text/html'
          expect(last_response.body).to eq 'Rackalicious'
        end

        it 'returns JPG response as text (original)' do
          get 'http://www.example.org/test.jpg'
          expect(last_response.headers['Content-Type']).to eq 'text/html'
          expect(last_response.body).to eq 'Rackalicious'
        end

        context 'when app configuration has JPEG middleware enabled' do
          before { allow(Grover.configuration).to receive(:use_jpeg_middleware).and_return true }

          it 'returns response as JPEG' do
            get 'http://www.example.org/test.jpeg'
            expect(last_response.headers['Content-Type']).to eq 'image/jpeg'
            expect(last_response.body.bytesize).to eq Grover.new('Rackalicious').to_jpeg.bytesize
          end

          it 'returns response as JPG' do
            get 'http://www.example.org/test.jpg'
            expect(last_response.headers['Content-Type']).to eq 'image/jpeg'
            expect(last_response.body.bytesize).to eq Grover.new('Rackalicious').to_jpeg.bytesize
          end
        end
      end

      context 'when response has multiple parts' do
        let(:response) { ['Part 1', 'Part 2'] }

        it 'returns response as PDF' do
          get 'http://www.example.org/test.pdf'
          expect(last_response.headers['Content-Type']).to eq 'application/pdf'
          expect(last_response.body.bytesize).to eq Grover.new('Part 1Part 2').to_pdf.bytesize
        end
      end
    end

    describe 'preprocessor' do
      it 'calls to the HTML preprocessor with the original HTML' do
        allow(Grover::HTMLPreprocessor).to(
          receive(:process).
            with('Grover McGroveryface', 'http://www.example.org/', 'http').
            and_return('Processed McProcessyface')
        )
        expect(Grover::HTMLPreprocessor).to(
          receive(:process).
            with('Grover McGroveryface', 'http://www.example.org/', 'http')
        )
        get 'http://www.example.org/test.pdf'
        expect(last_response.body.bytesize).to eq Grover.new('Processed McProcessyface').to_pdf.bytesize
      end

      context 'with root_url specified as an argument' do
        subject(:mock_app) do
          builder = Rack::Builder.new
          builder.use described_class, root_url: 'http://example.com/'
          builder.run downstream
          builder.to_app
        end

        it 'calls to the HTML preprocessor with the original HTML and the specified root_url' do
          allow(Grover::HTMLPreprocessor).to(
            receive(:process).
              with('Grover McGroveryface', 'http://example.com/', 'http').
              and_return('Processed McProcessyface')
          )
          expect(Grover::HTMLPreprocessor).to(
            receive(:process).
              with('Grover McGroveryface', 'http://example.com/', 'http')
          )
          get 'http://www.example.org/test.pdf'
          expect(last_response.body.bytesize).to eq Grover.new('Processed McProcessyface').to_pdf.bytesize
        end
      end

      context 'when the response contains relative paths' do
        let(:response) { ['src="/asdf"'] }

        context 'with root_url specified via middleware args' do
          subject(:mock_app) do
            builder = Rack::Builder.new
            builder.use described_class, root_url: 'http://example.com/'
            builder.run downstream
            builder.to_app
          end

          it 'uses the specified root_url' do
            get 'http://www.example.org/test.pdf'
            expect(last_response.body.bytesize).to eq Grover.new('src="http://example.com/asdf"').to_pdf.bytesize
          end

          context 'when the root_url is also set in configuration' do
            before { allow(Grover.configuration).to receive(:root_url).and_return 'http://other.domain/' }

            it 'uses the specified root_url in the middleware initializer' do
              get 'http://www.example.org/test.pdf'
              expect(last_response.body.bytesize).to eq Grover.new('src="http://example.com/asdf"').to_pdf.bytesize
            end
          end
        end

        context 'with root_url set in configuration' do
          before { allow(Grover.configuration).to receive(:root_url).and_return 'http://example.com/' }

          it 'uses the specified root_url' do
            get 'http://www.example.org/test.pdf'
            expect(last_response.body.bytesize).to eq Grover.new('src="http://example.com/asdf"').to_pdf.bytesize
          end
        end

        context 'without root_url specified' do
          it 'uses the detected root_url (request url)' do
            get 'http://www.example.org/test.pdf'
            expect(last_response.body.bytesize).to eq Grover.new('src="http://www.example.org/asdf"').to_pdf.bytesize
          end
        end
      end
    end

    describe 'pdf conversion' do
      let(:grover) { instance_double Grover, show_front_cover?: false, show_back_cover?: false }

      it 'passes through the request URL (sans extension) to Grover' do
        allow(Grover).to(
          receive(:new).
            with('Grover McGroveryface', display_url: 'http://www.example.org/test').
            and_return(grover)
        )
        allow(grover).to receive(:to_pdf).with(no_args).and_return 'A converted PDF'
        expect(Grover).to receive(:new).with('Grover McGroveryface', display_url: 'http://www.example.org/test')
        expect(grover).to receive(:to_pdf).with(no_args)
        get 'http://www.example.org/test.pdf'
        expect(last_response.body).to eq 'A converted PDF'
      end

      { 'key' => 'value', 'escaped' => '%26%3D%3D' }.each do |k, v|
        it 'passes cookies to Grover' do
          allow(Grover).to receive(:new).with(
            'Grover McGroveryface',
            display_url: 'http://www.example.org/test',
            cookies: [{ domain: 'www.example.org', name: k, value: v }]
          ).and_return(grover)
          allow(grover).to receive(:to_pdf).with(no_args).and_return 'A converted PDF'
          expect(Grover).to receive(:new).with(
            'Grover McGroveryface',
            display_url: 'http://www.example.org/test',
            cookies: [{ domain: 'www.example.org', name: k, value: v }]
          )
          expect(grover).to receive(:to_pdf).with(no_args)
          get 'http://www.example.org/test.pdf', nil, 'HTTP_COOKIE' => "#{k}=#{v}"
          expect(last_response.body).to eq 'A converted PDF'
        end
      end

      context 'when app configuration has PDF middleware disabled' do
        before { allow(Grover.configuration).to receive(:use_pdf_middleware).and_return false }

        it 'doesnt call to Grover' do
          expect(Grover).not_to receive(:new)
          get 'http://www.example.org/test.pdf'
          expect(last_response.body).to eq 'Grover McGroveryface'
        end
      end
    end

    describe 'png conversion' do
      let(:grover) { instance_double Grover, show_front_cover?: false, show_back_cover?: false }

      it 'doesnt call to Grover' do
        expect(Grover).not_to receive(:new)
        get 'http://www.example.org/test.png'
        expect(last_response.body).to eq 'Grover McGroveryface'
      end

      context 'when app configuration has PNG middleware enabled' do
        before { allow(Grover.configuration).to receive(:use_png_middleware).and_return true }

        it 'passes through the request URL (sans extension) to Grover' do
          allow(Grover).to(
            receive(:new).
              with('Grover McGroveryface', display_url: 'http://www.example.org/test').
              and_return(grover)
          )
          allow(grover).to receive(:to_png).with(no_args).and_return 'A converted PNG'
          expect(Grover).to receive(:new).with('Grover McGroveryface', display_url: 'http://www.example.org/test')
          expect(grover).to receive(:to_png).with(no_args)
          get 'http://www.example.org/test.png'
          expect(last_response.body).to eq 'A converted PNG'
        end
      end
    end

    describe 'jpeg conversion' do
      let(:grover) { instance_double Grover, show_front_cover?: false, show_back_cover?: false }

      it 'doesnt call to Grover' do
        expect(Grover).not_to receive(:new)
        get 'http://www.example.org/test.jpeg'
        expect(last_response.body).to eq 'Grover McGroveryface'
      end

      context 'when app configuration has JPEG middleware enabled' do
        before { allow(Grover.configuration).to receive(:use_jpeg_middleware).and_return true }

        it 'passes through the request URL (sans extension) to Grover' do
          allow(Grover).to(
            receive(:new).
              with('Grover McGroveryface', display_url: 'http://www.example.org/test').
              and_return(grover)
          )
          allow(grover).to receive(:to_jpeg).with(no_args).and_return 'A converted JPEG'
          expect(Grover).to receive(:new).with('Grover McGroveryface', display_url: 'http://www.example.org/test')
          expect(grover).to receive(:to_jpeg).with(no_args)
          get 'http://www.example.org/test.jpeg'
          expect(last_response.body).to eq 'A converted JPEG'
        end
      end
    end

    describe 'front and back cover pages' do
      let(:pdf_reader) { PDF::Reader.new pdf_io }
      let(:pdf_io) { StringIO.new last_response.body }

      before { get 'http://www.example.org/test.pdf' }

      context 'when the downstream response includes front cover page configuration' do
        let(:downstream) do
          lambda do |env|
            response =
              if env['PATH_INFO'] == '/front/page/meta'
                <<-HTML
                  <p>This is the cover page with params:</p>
                  <p>Query string: #{env['QUERY_STRING']}</p>
                  <p>Parameters: #{env['action_dispatch.request.parameters']}</p>
                  <p>Query params: #{env['action_dispatch.request.query_parameters']}</p>
                  <p>Request params: #{env['action_dispatch.request.request_parameters']}</p>
                HTML
              else
                # Can't directly test the helpers for these as they're in Rails, but we can
                # test that they're not persisted in the subsequent cover page request
                env['action_dispatch.request.parameters'] = 'Original params' # Overall Rails param cache
                env['action_dispatch.request.query_parameters'] = 'Original query params' # get params cache
                env['action_dispatch.request.request_parameters'] = 'Original request params' # post params cache
                Grover::Utils.squish <<-HTML
                  <html>
                    <head>
                      <title>Paaage</title>
                      <meta name="grover-front_cover_path" content="/front/page/meta?queryparam=baz" />
                    </head>
                    <body>
                      <h1>Hey there</h1>
                    </body>
                  </html>
                HTML
              end

            [200, headers.merge('Content-Length' => response.length.to_s), [response]]
          end
        end

        it { expect(pdf_reader.page_count).to eq 2 }

        it 'contains expected first page text' do
          expect(Grover::Utils.squish(pdf_reader.pages[0].text)).to eq Grover::Utils.squish <<-HTML
            This is the cover page with params:
            Query string: queryparam=baz
            Parameters:
            Query params:
            Request params:
          HTML
        end

        it { expect(Grover::Utils.squish(pdf_reader.pages[1].text)).to eq 'Hey there' }
      end

      context 'when the downstream response includes back cover page configuration' do
        let(:downstream) do
          lambda do |env|
            response =
              if env['PATH_INFO'] == '/back/page/meta'
                "This is the back page with params #{env['QUERY_STRING']}"
              else
                Grover::Utils.squish <<-HTML
                  <html>
                    <head>
                      <title>Paaage</title>
                      <meta name="grover-back_cover_path" content="/back/page/meta?anotherquery=foo" />
                    </head>
                    <body>
                      <h1>Hey there</h1>
                    </body>
                  </html>
                HTML
              end

            [200, headers.merge('Content-Length' => response.length.to_s), [response]]
          end
        end

        it { expect(pdf_reader.page_count).to eq 2 }
        it { expect(Grover::Utils.squish(pdf_reader.pages[0].text)).to eq 'Hey there' }

        it 'contains expected second page text' do
          expect(Grover::Utils.squish(pdf_reader.pages[1].text)).to(
            eq('This is the back page with params anotherquery=foo')
          )
        end
      end
    end

    describe '#grover_request?' do
      it 'does not get stuck rendering each request as pdf' do
        # renders html by default
        response = get 'http://www.example.org/test'
        expect(response.content_type).to eq 'text/html'

        response = get 'http://www.example.org/test.html'
        expect(response.content_type).to eq 'text/html'

        response = get 'http://www.example.org/test.pdf'
        expect(response.content_type).to eq 'application/pdf'

        response = get 'http://www.example.org/test'
        expect(response.content_type).to eq 'text/html'
      end

      context 'when app configuration has PDF middleware disabled' do
        before { allow(Grover.configuration).to receive(:use_pdf_middleware).and_return false }

        it 'does not handle pdf requests' do
          # renders html by default
          response = get 'http://www.example.org/test'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/test.pdf'
          expect(response.content_type).to eq 'text/html'
        end
      end

      it 'does not handle png requests' do
        # renders html by default
        response = get 'http://www.example.org/test'
        expect(response.content_type).to eq 'text/html'

        response = get 'http://www.example.org/test.png'
        expect(response.content_type).to eq 'text/html'
      end

      context 'when app configuration has PNG middleware enabled' do
        before { allow(Grover.configuration).to receive(:use_png_middleware).and_return true }

        it 'does not get stuck rendering each request as png' do
          # renders html by default
          response = get 'http://www.example.org/test'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/test.html'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/test.png'
          expect(response.content_type).to eq 'image/png'

          response = get 'http://www.example.org/test'
          expect(response.content_type).to eq 'text/html'
        end
      end

      it 'does not handle jpeg requests' do
        # renders html by default
        response = get 'http://www.example.org/test'
        expect(response.content_type).to eq 'text/html'

        response = get 'http://www.example.org/test.jpeg'
        expect(response.content_type).to eq 'text/html'
      end

      it 'does not handle jpg requests' do
        # renders html by default
        response = get 'http://www.example.org/test'
        expect(response.content_type).to eq 'text/html'

        response = get 'http://www.example.org/test.jpg'
        expect(response.content_type).to eq 'text/html'
      end

      context 'when app configuration has JPEG middleware enabled' do
        before { allow(Grover.configuration).to receive(:use_jpeg_middleware).and_return true }

        it 'does not get stuck rendering each request as jpeg' do
          # renders html by default
          response = get 'http://www.example.org/test'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/test.html'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/test.jpeg'
          expect(response.content_type).to eq 'image/jpeg'

          response = get 'http://www.example.org/test'
          expect(response.content_type).to eq 'text/html'
        end

        it 'does not get stuck rendering each request as jpg' do
          # renders html by default
          response = get 'http://www.example.org/test'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/test.html'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/test.jpg'
          expect(response.content_type).to eq 'image/jpeg'

          response = get 'http://www.example.org/test'
          expect(response.content_type).to eq 'text/html'
        end
      end
    end

    describe '#ignore_path?' do
      context 'when app configuration has a String for ignore_path' do
        before { allow(Grover.configuration).to receive(:ignore_path).and_return '/foo/bar' }

        it 'request is ignored when the request path starts with the ignore_path' do
          response = get 'http://www.example.org/foo/bar/baz'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/foo/bar/baz.pdf'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/foo/baz/bar'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/foo/baz/bar.pdf'
          expect(response.content_type).to eq 'application/pdf'
        end
      end

      context 'when app configuration has a Regexp for ignore_path' do
        before { allow(Grover.configuration).to receive(:ignore_path).and_return %r{foo/bar} }

        it 'request is ignored when the request path matches the ignore_path' do
          response = get 'http://www.example.org/baz/foo/bar/baz'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/baz/foo/bar/baz.pdf'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/bar/foo/baz/bar'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/bar/foo/baz/bar.pdf'
          expect(response.content_type).to eq 'application/pdf'
        end
      end

      context 'when app configuration has a Proc for ignore_path' do
        before { allow(Grover.configuration).to receive(:ignore_path).and_return(->(path) { path.include? 'baz' }) }

        it 'request is ignored when the request path passed to the proc defined in ignore_path returns true' do
          response = get 'http://www.example.org/foobazbar'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/foobazbar.pdf'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/foobarbar'
          expect(response.content_type).to eq 'text/html'

          response = get 'http://www.example.org/foobarbar.pdf'
          expect(response.content_type).to eq 'application/pdf'
        end
      end
    end

    describe '#ignore_request?' do
      context 'when app configuration has a Proc for ignore_request' do
        context 'with a hostname' do
          before { allow(Grover.configuration).to receive(:ignore_request).and_return(->(req) { req.host == 'www.example.org' }) }

          it 'request is ignored when the request passed to the proc defined in ignore_request returns true' do
            response = get 'http://www.example.org/foobazbar'
            expect(response.content_type).to eq 'text/html'

            response = get 'http://www.example.org/foobazbar.pdf'
            expect(response.content_type).to eq 'text/html'

            response = get 'http://www.therealexample.org/foobarbar'
            expect(response.content_type).to eq 'text/html'

            response = get 'http://www.therealexample.org/foobarbar.pdf'
            expect(response.content_type).to eq 'application/pdf'
          end
        end

        context 'with a custom header' do
          before { allow(Grover.configuration).to receive(:ignore_request).and_return(->(req) { req.has_header?('X-BLOCK') }) }

          it 'request is ignored when the request passed to the proc defined in ignore_request returns true' do
            response = get 'http://www.example.org/foobazbar', {}, { 'X-BLOCK' => '1' }
            expect(response.content_type).to eq 'text/html'

            response = get 'http://www.example.org/foobarbar.pdf', {}, { 'X-BLOCK' => '1' }
            expect(response.content_type).to eq 'text/html'

            response = get 'http://www.therealexample.org/foobazbar'
            expect(response.content_type).to eq 'text/html'

            response = get 'http://www.therealexample.org/foobarbar.pdf'
            expect(response.content_type).to eq 'application/pdf'
          end
        end
      end
    end

    context 'with a downstream app that can respond to different paths' do
      let(:downstream) do
        lambda do |env|
          response =
            case env['PATH_INFO']
            when '/test1' then 'Test1 page contents'
            when '/test2' then 'Test2 page contents'
            else 'Default page contents'
            end

          [200, headers.merge('Content-Length' => response.length.to_s), [response]]
        end
      end

      it 'does not cache any results from previous requests' do
        # Non-PDF request
        get 'http://www.example.org/test1'
        expect(last_response.body).to eq 'Test1 page contents'

        # PDF request for 'test 1'
        get 'http://www.example.org/test1.pdf'
        expect(last_response.body).to be_a_pdf
        check_response_pdf contents: 'Test1 page contents'

        # PDF request for 'test 2'
        get 'http://www.example.org/test2.pdf'
        expect(last_response.body).to be_a_pdf
        check_response_pdf contents: 'Test2 page contents'

        # Non-PDF request
        get 'http://www.example.org/test1'
        expect(last_response.body).to eq 'Test1 page contents'
      end

      def check_response_pdf(contents:)
        pdf_reader = pdf_reader_from_response
        expect(pdf_reader.page_count).to eq 1
        expect(Grover::Utils.squish(pdf_reader.pages.first.text)).to eq contents
      end

      def pdf_reader_from_response
        pdf_io = StringIO.new last_response.body
        PDF::Reader.new pdf_io
      end

      def be_a_pdf
        match(/^%PDF-1\.4/)
      end
    end

    describe 'thread safety' do
      let(:thread_count) { 30 }
      let(:extensions) { Array.new(thread_count) { rand > 0.5 ? 'html' : 'pdf' } }
      let(:response_content_types) { {} }
      let(:threads) do
        (0...thread_count).map do |i|
          Thread.new do
            response = get "http://www.example.org/test.#{extensions[i]}"
            response_content_types[i] = response.content_type
          end
        end
      end

      before { mock_app }

      it 'is threadsafe' do
        threads.each(&:join)

        extensions.each_with_index do |extension, index|
          response_content_type = response_content_types[index]

          case extension
          when 'html'
            expect(response_content_type).to eq 'text/html'
          when 'pdf'
            expect(response_content_type).to eq 'application/pdf'
          end
        end
      end
    end
  end
end
