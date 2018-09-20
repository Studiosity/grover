require 'spec_helper'

describe Grover::Middleware do
  # rubocop:disable RSpec/MultipleExpectations

  subject(:mock_app) do
    builder = Rack::Builder.new
    builder.use described_class
    builder.run upstream
    builder.to_app
  end

  let(:upstream) do
    lambda do |env|
      @env = env
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

      context 'when request doesnt have an extension' do
        it 'returns the upstream content type' do
          get 'http://www.example.org/test'
          expect(last_response.headers['Content-Type']).to eq 'text/html'
          expect(last_response.body).to eq 'Grover McGroveryface'
          expect(last_response.headers['Content-Length']).to eq '20'
        end
      end

      context 'when request has a non-PDF extension' do
        it 'returns the upstream content type' do
          get 'http://www.example.org/test.html'
          expect(last_response.headers['Content-Type']).to eq 'text/html'
          expect(last_response.body).to eq 'Grover McGroveryface'
          expect(last_response.headers['Content-Length']).to eq '20'
        end
      end
    end

    describe 'rack environment' do
      # rubocop:disable RSpec/InstanceVariable
      context 'when requesting a PDF' do
        it 'removes PDF extension from PATH_INFO and REQUEST_URI' do
          get 'http://www.example.org/test.pdf'
          expect(@env['PATH_INFO']).to eq '/test'
          expect(@env['REQUEST_URI']).to eq '/test'
          expect(@env['Rack-Middleware-Grover']).to eq 'true'
        end
      end

      context 'when not requesting a PDF' do
        it 'keeps the original PATH_INFO and not change to REQUEST_URI' do
          get 'http://www.example.org/test.html'
          expect(@env['PATH_INFO']).to eq '/test.html'
          expect(@env['REQUEST_URI']).to be_nil
          expect(@env['Rack-Middleware-Grover']).to be_nil
        end
      end
      # rubocop:enable RSpec/InstanceVariable
    end

    describe 'caching' do
      context 'when requesting a PDF' do
        it 'deletes the cache headers' do
          get 'http://www.example.org/test.pdf'
          expect(last_response.headers).not_to have_key 'ETag'
          expect(last_response.headers).not_to have_key 'Cache-Control'
        end
      end

      context 'when not requesting a PDF' do
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
        expect(Grover::HTMLPreprocessor).to(
          receive(:process).
            with('Grover McGroveryface', 'http://www.example.org/', 'http').
            and_return('Processed McProcessyface')
        )
        get 'http://www.example.org/test.pdf'
        expect(last_response.body.bytesize).to eq Grover.new('Processed McProcessyface').to_pdf.bytesize
      end
    end

    describe 'pdf conversion' do
      let(:grover) { instance_double Grover, show_front_cover?: false, show_back_cover?: false }

      it 'passes through the request URL (sans extension) to Grover' do
        expect(Grover).to(
          receive(:new).
            with('Grover McGroveryface', display_url: 'http://www.example.org/test', cache: false).
            and_return(grover)
        )
        expect(grover).to receive(:to_pdf).with(no_args).and_return 'A converted PDF'
        get 'http://www.example.org/test.pdf'
        expect(last_response.body).to eq 'A converted PDF'
      end
    end

    describe 'front and back cover pages' do
      let(:pdf_reader) { PDF::Reader.new pdf_io }
      let(:pdf_io) { StringIO.new last_response.body }

      before { get 'http://www.example.org/test.pdf' }

      context 'when the upstream response includes front cover page configuration' do
        let(:upstream) do
          lambda do |env|
            @env = env
            response =
              if env['PATH_INFO'] == '/front/page/meta'
                "This is the cover page with params #{env['QUERY_STRING']}"
              else
                Grover::Utils.squish(<<-HTML)
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
        it do
          expect(Grover::Utils.squish(pdf_reader.pages[0].text)).to(
            eq('This is the cover page with params queryparam=baz')
          )
        end
        it { expect(Grover::Utils.squish(pdf_reader.pages[1].text)).to eq 'Hey there' }
      end

      context 'when the upstream response includes back cover page configuration' do
        let(:upstream) do
          lambda do |env|
            @env = env
            response =
              if env['PATH_INFO'] == '/back/page/meta'
                "This is the back page with params #{env['QUERY_STRING']}"
              else
                Grover::Utils.squish(<<-HTML)
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
        it do
          expect(Grover::Utils.squish(pdf_reader.pages[1].text)).to(
            eq('This is the back page with params anotherquery=foo')
          )
        end
      end
    end

    it 'does not get stuck rendering each request as pdf' do
      # false by default. No requests.
      expect(mock_app.send(:rendering_pdf?)).to eq false

      # Remain false on a normal request
      get 'http://www.example.org/test.html'
      expect(mock_app.send(:rendering_pdf?)).to eq false

      # Return true on a pdf request.
      get 'http://www.example.org/test.pdf'
      expect(mock_app.send(:rendering_pdf?)).to eq true

      # Restore to false on any non-pdf request.
      get 'http://www.example.org/test.html'
      expect(mock_app.send(:rendering_pdf?)).to eq false
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
