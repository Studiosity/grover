# frozen_string_literal: true

require 'spec_helper'

describe Grover::Processor do
  subject(:processor) { described_class.new Dir.pwd }

  describe '#convert' do
    subject(:convert) { processor.convert method, url_or_html, options }

    let(:url_or_html) { 'http://google.com' }
    let(:options) { {} }

    context 'when converting to PDF' do
      let(:method) { :pdf }

      let(:pdf_reader) { PDF::Reader.new pdf_io }
      let(:pdf_io) { StringIO.new convert }
      let(:pdf_text_content) { Grover::Utils.squish(pdf_reader.pages.first.text) }
      let(:large_text) { '<style>.text { font-size: 14px; }</style>' }
      let(:default_header) { Grover::DEFAULT_HEADER_TEMPLATE }
      let(:basic_header_footer_options) do
        {
          'displayHeaderFooter' => true,
          'displayUrl' => 'http://www.example.net/foo/bar',
          'margin' => {
            'top' => '1in',
            'bottom' => '1in'
          }
        }
      end

      it 'cleans up the worker process' do
        expect { convert }.not_to(change { `ps | grep node | grep -v 'grep node' | wc -l` })
      end

      context 'when passing through a valid URL' do
        # we need to add the language for test stability
        # if not added explicitly, google can respond with a different locale
        # based on IP address geo-lookup, timezone, etc.
        let(:url_or_html) { 'https://www.google.com/?gl=us' }

        it { is_expected.to start_with "%PDF-1.4\n" }
        it { expect(pdf_reader.page_count).to eq 1 }
        it { expect(pdf_text_content).to include "I'm Feeling Lucky" }
      end

      context 'when passing through an invalid URL' do
        let(:url_or_html) { 'https://fake.invalid' }

        it 'raises a JavaScript error warning that the URL could not be resolved' do
          expect do
            convert
          end.to raise_error Grover::JavaScript::Error, %r{net::ERR_NAME_NOT_RESOLVED at https://fake.invalid}
        end
      end

      context 'when passing through an empty string' do
        let(:url_or_html) { '' }

        it { is_expected.to start_with "%PDF-1.4\n" }
        it { expect(pdf_reader.page_count).to eq 1 }
        it { expect(pdf_text_content).to eq '' }
      end

      context 'when puppeteer package is not installed' do
        # Temporarily move the node puppeteer folder
        before { FileUtils.move 'node_modules/puppeteer', 'node_modules/puppeteer_temp' }

        after { FileUtils.move 'node_modules/puppeteer_temp', 'node_modules/puppeteer' }

        it 'raises a DependencyError' do
          expect { convert }.to raise_error Grover::DependencyError, Grover::Utils.squish(<<~ERROR)
            Cannot find module 'puppeteer'.
            The module was found in '#{Dir.pwd}/package.json' however, please run 'npm install' from '#{Dir.pwd}'
          ERROR
        end

        context 'when puppeteer package is not in package.json' do
          before do
            FileUtils.copy 'package.json', 'package.json.tmp'
            IO.write('package.json', File.open('package.json') { |f| f.read.gsub(/"puppeteer"/, '"puppeteer-tmp"') })
          end

          after { FileUtils.move 'package.json.tmp', 'package.json' }

          it 'raises a DependencyError' do
            expect { convert }.to raise_error Grover::DependencyError, Grover::Utils.squish(<<~ERROR)
              Cannot find module 'puppeteer'.
              You need to add it to '#{Dir.pwd}/package.json' and run 'npm install'
            ERROR
          end
        end
      end

      context 'when stubbing the call to the Node processor' do
        let(:stdin) { instance_double 'IO' }
        let(:stdout) { instance_double 'IO' }
        let(:stderr) { instance_double 'IO' }
        let(:wait_thr) { instance_double 'Process::Waiter' }

        before do
          allow(Open3).to(
            receive(:popen3).
              with('node', File.expand_path(File.join(__dir__, '../../lib/grover/js/processor.js')), chdir: Dir.pwd).
              and_return([stdin, stdout, stderr, wait_thr])
          )

          allow(stdin).to receive(:close)
          allow(stdout).to receive(:close)
          allow(stderr).to receive(:close)
          allow(wait_thr).to receive(:join)
        end

        context 'when first call to gets on stdout returns nil' do
          before do
            allow(stdout).to receive(:gets).and_return nil
            allow(stderr).to receive(:read).and_return 'The reason the worker failed'
          end

          it 'raises an Error' do
            expect { convert }.to raise_error Grover::Error, <<~ERROR.strip
              Failed to instantiate worker process:
              The reason the worker failed
            ERROR
          end
        end

        context 'when first call to gets on stdout succeeds but second returns nil' do
          before do
            allow(stdout).to receive(:gets).and_return '["ok"]', nil
            allow(stdin).to receive(:puts).with '["pdf","http://google.com",{}]'
            allow(stderr).to receive(:read).and_return 'The reason the worker failed'
          end

          it 'raises an Error' do
            expect { convert }.to raise_error Grover::Error, <<~ERROR.strip
              Worker process failed:
              The reason the worker failed
            ERROR
          end
        end

        context 'when first call to gets on stdout succeeds but second returns an error' do
          before do
            allow(stdout).to receive(:gets).and_return '["ok"]', '["err","Some unknown thing happened"]'
            allow(stdin).to receive(:puts).with '["pdf","http://google.com",{}]'
            allow(stderr).to receive(:read).and_return 'The reason the worker failed'
          end

          it 'raises a JavaScript UnknownError' do
            expect { convert }.to raise_error Grover::JavaScript::UnknownError, 'Some unknown thing happened'
          end
        end

        context 'when the call to launch Node raises an error' do
          it 'raises the error' do
            expect(Open3).to receive(:popen3).and_raise Errno::ENOENT, 'node'

            expect { convert }.to raise_error Errno::ENOENT, 'No such file or directory - node'
          end
        end

        context 'when the worker returns an invalid response' do
          before do
            allow(stdout).to receive(:gets).and_return '["ok"]', '["ok",invalid_response]'
            allow(stdin).to receive(:puts).with '["pdf","http://google.com",{}]'
          end

          it 'raises an Error' do
            expect { convert }.to raise_error Grover::Error, 'Malformed worker response'
          end
        end
      end

      context 'when passing through html' do
        let(:url_or_html) { '<html><body><h1>Hey there</h1></body></html>' }

        it { is_expected.to start_with "%PDF-1.4\n" }
        it { expect(pdf_reader.page_count).to eq 1 }
        it { expect(pdf_text_content).to eq 'Hey there' }
      end

      context 'when passing through options to Grover' do
        let(:url_or_html) { '<html><head><title>Paaage</title></head><body><h1>Hey there</h1></body></html>' }

        context 'when options includes A4 page format' do
          let(:options) { { format: 'A4' } }

          it { expect(pdf_reader.pages.first.attributes).to include(MediaBox: [0, 0, 594.95996, 841.91998]) }
        end

        context 'when options includes Letter page format' do
          let(:options) { { format: 'Letter' } }

          it { expect(pdf_reader.pages.first.attributes).to include(MediaBox: [0, 0, 612, 792]) }
        end

        context 'when the page contains a line starting with `http`' do
          let(:options) do
            basic_header_footer_options.merge(
              'headerTemplate' => large_text,
              'footerTemplate' => "#{large_text}<div class='text'>Footer content</div>"
            )
          end
          let(:url_or_html) do
            <<~HTML
              <html>
                <body>
                  <h1>Hey there</h1>
              http://example.com
                </body>
              </html>
            HTML
          end

          it { expect(pdf_text_content).to eq 'Hey there http://example.com Footer content' }
        end

        context 'when the options disable display of header/footer' do
          let(:options) do
            basic_header_footer_options.
              merge('headerTemplate' => 'We dont expect to see this...', 'displayHeaderFooter' => false)
          end

          it { expect(pdf_text_content).to eq 'Hey there' }
        end

        context 'when the options include invalid values' do
          let(:options) { basic_header_footer_options.merge('margin' => { 'top' => 'totes-invalid' }) }

          it do
            expect do
              convert
            end.to raise_error Grover::JavaScript::Error, /Failed to parse parameter value: totes-invalid/
          end
        end

        context 'when options include header and footer enabled' do
          let(:options) { basic_header_footer_options.merge('headerTemplate' => "#{large_text}#{default_header}") }

          it do
            date = Date.today.strftime '%-m/%-d/%Y'
            expect(pdf_text_content).to eq "#{date} Paaage Hey there http://www.example.net/foo/bar 1/1"
          end
        end

        context 'when options override header template' do
          let(:options) do
            basic_header_footer_options.merge('headerTemplate' => "#{large_text}<div class='text'>Excellente</div>")
          end

          it { expect(pdf_text_content).to eq 'Excellente Hey there http://www.example.net/foo/bar 1/1' }
        end

        context 'when header template includes the display url marker' do
          let(:options) do
            basic_header_footer_options.merge(
              'headerTemplate' => "#{large_text}<div class='text'>abc<span class='url'></span>def</div>"
            )
          end

          it do
            expect(pdf_text_content).to(
              eq('abchttp://www.example.net/foo/bardef Hey there http://www.example.net/foo/bar 1/1')
            )
          end
        end

        context 'when options override footer template' do
          let(:options) { basic_header_footer_options.merge('footerTemplate' => footer_template) }
          let(:footer_template) { "#{large_text}<div class='text'>great <span class='url'></span> page</div>" }

          it do
            date = Date.today.strftime '%-m/%-d/%Y'
            expect(pdf_text_content).to eq "#{date} Paaage Hey there great http://www.example.net/foo/bar page"
          end

          context 'when template contains quotes' do
            let(:footer_template) { %(<div class='text'>Footer with "quotes" in it</div>) }

            it { expect(pdf_text_content).to include('Hey there Footer with "quotes" in it') }
          end
        end

        context 'when displayUrl option is not provided' do
          let(:options) { basic_header_footer_options.tap { |hash| hash.delete('displayUrl') } }

          it 'uses the default `example.com` for the footer URL' do
            date = Date.today.strftime '%-m/%-d/%Y'
            expect(pdf_text_content).to eq "#{date} Paaage Hey there http://example.com/ 1/1"
          end
        end

        context 'when passing through launch params' do
          let(:options) { { 'launchArgs' => launch_args } }
          let(:launch_args) { [] }
          let(:url_or_html) do
            <<-HTML
              <html>
                #{head}
                <body>
                  Speech recognition is <span id="test" />
                  <script type="text/javascript">
                    var speechSupported = "webkitSpeechRecognition" in window;
                    document.getElementById("test").innerHTML = speechSupported ? "supported" : "not supported"
                  </script>
                </body>
              </html>
            HTML
          end
          let(:head) { '' }

          it { expect(pdf_text_content).to eq 'Speech recognition is supported' }

          context 'when launch params specify disabling the speech API' do
            let(:launch_args) { ['--disable-speech-api'] }

            it { expect(pdf_text_content).to eq 'Speech recognition is not supported' }
          end
        end

        context 'when passing through waitUntil option' do
          let(:url_or_html) do
            <<-HTML
              <html>
                <body>
                  Delayed JavaScript <span id="test">did not run</span>
                  <script type="text/javascript">
                    setTimeout(function() { document.getElementById("test").innerHTML = "ran"; }, 250);
                  </script>
                </body>
              </html>
            HTML
          end

          it { expect(pdf_text_content).to eq 'Delayed JavaScript ran' }

          context 'when setting waitUntil option to load' do
            let(:options) { { 'waitUntil' => 'load' } }

            it { expect(pdf_text_content).to eq 'Delayed JavaScript did not run' }
          end
        end

        context 'when options include executablePath' do
          let(:options) { { 'executablePath' => '/totes/invalid/path' } }

          it do
            expect do
              convert
            end.to raise_error Grover::JavaScript::Error,
                               %r{Failed to launch (chrome|the browser process)! spawn /totes/invalid/path}
          end
        end

        context 'when requesting a URI requiring basic authentication' do
          let(:url_or_html) { 'https://jigsaw.w3.org/HTTP/Basic/' }

          it { expect(pdf_text_content).to eq 'Unauthorized access You are denied access to this resource.' }

          context 'when passing through `username` and `password` options' do
            let(:options) { { username: 'guest', password: 'guest' } }

            it { expect(pdf_text_content).to eq 'Your browser made it!' }
          end
        end

        context 'when passing through cookies option' do
          let(:url_or_html) { 'https://cookie-renderer.herokuapp.com/' }
          let(:options) do
            {
              'cookies' => [
                { 'name' => 'grover-test', 'value' => 'nom nom nom', 'domain' => 'cookie-renderer.herokuapp.com' },
                { 'name' => 'other-domain', 'value' => 'should not display', 'domain' => 'example.com' },
                { 'name' => 'escaped', 'value' => '%26%3D%3D', 'domain' => 'cookie-renderer.herokuapp.com' }
              ]
            }
          end

          it { expect(pdf_text_content).to include 'Request contained 2 cookies' }
          it { expect(pdf_text_content).to include '1. grover-test nom nom nom' }
          it { expect(pdf_text_content).to include '2. escaped &==' }
        end

        context 'when passing through extra HTTP headers' do
          let(:url_or_html) { 'http://cookie-renderer.herokuapp.com/?type=headers' }
          let(:options) { { 'extraHTTPHeaders' => { 'grover-test' => 'yes it is' } } }

          it { expect(pdf_text_content).to match(/Request contained (15|16) headers/) }
          it { expect(pdf_text_content).to include '1. host cookie-renderer.herokuapp.com' }
          it { expect(pdf_text_content).to include '5. grover-test yes it is' }
        end

        context 'when overloading the user agent' do
          let(:url_or_html) { 'http://cookie-renderer.herokuapp.com/?type=headers' }
          let(:options) { { 'userAgent' => 'Grover user agent' } }

          it { expect(pdf_text_content).to match(/Request contained (14|15) headers/) }
          it { expect(pdf_text_content).to include '1. host cookie-renderer.herokuapp.com' }
          it { expect(pdf_text_content).to include 'user-agent Grover user agent' }
        end
      end

      context 'when HTML includes screen only content' do
        let(:url_or_html) do
          <<-HTML
            <html>
              <head>
                <style>
                  @media not screen {
                    .screen-only { display: none }
                  }
                </style>
              </head>
              <body>
                <h1>Hey there</h1>
                <div class="screen-only">This should only display for screen media</div>
              </body>
            </html>
          HTML
        end

        it { expect(pdf_text_content).to eq 'Hey there' }

        context 'with emulateMedia set to `screen`' do
          let(:options) { { 'emulateMedia' => 'screen' } }

          it { expect(pdf_text_content).to eq 'Hey there This should only display for screen media' }
        end
      end

      # Only test `emulateMediaFeatures` if the Puppeteer supports it
      if puppeteer_version_on_or_after? '2.0.0'
        context 'when the browser timezone is rendered' do
          let(:url_or_html) do
            <<-HTML
              <html>
                <body>
                  Timezone offset is
                  <div id="timezone"></div>
                  <script>document.getElementById("timezone").innerHTML = new Date().getTimezoneOffset();</script>
                </body>
              </html>
            HTML
          end

          it { expect(pdf_text_content).to eq "Timezone offset is #{Time.now.utc_offset / -60}" }

          context 'when timezone is overridden with Brisbane' do
            let(:options) { { 'timezone' => 'Australia/Brisbane' } }

            it { expect(pdf_text_content).to eq 'Timezone offset is -600' }
          end

          context 'when timezone is overridden with Dhaka' do
            let(:options) { { 'timezone' => 'Asia/Dhaka' } }

            it { expect(pdf_text_content).to eq 'Timezone offset is -360' }
          end
        end
      end

      context 'when evaluate option is specified' do
        let(:url_or_html) { '<html><body></body></html>' }
        let(:options) { basic_header_footer_options.merge('executeScript' => script) }
        let(:script) { 'document.getElementsByTagName("body")[0].innerText = "Some evaluated content"' }
        let(:date) { Date.today.strftime '%-m/%-d/%Y' }

        it { expect(pdf_text_content).to eq "#{date} Some evaluated content http://www.example.net/foo/bar 1/1" }
      end

      context 'when wait for selector option is specified' do
        let(:url_or_html) do
          <<-HTML
            <html>
              <body></body>

              <script>
                setTimeout(function() {
                  document.body.innerHTML = '<h1>Hey there</h1>';
                }, 100);
              </script>
            </html>
          HTML
        end
        let(:options) { basic_header_footer_options.merge('waitForSelector' => 'h1') }
        let(:date) { Date.today.strftime '%-m/%-d/%Y' }

        it { expect(pdf_text_content).to eq "#{date} Hey there http://www.example.net/foo/bar 1/1" }
      end

      context 'when wait for function option is specified' do
        let(:url_or_html) do
          <<-HTML
            <html>
              <body></body>

              <script>
                var doneProcessing = false

                setTimeout(function() {
                  doneProcessing = true
                  document.body.innerHTML = '<h1 id="test">Hey there</h1>';
                }, 100);
              </script>
            </html>
          HTML
        end
        let(:options) do
          basic_header_footer_options.merge(
            'waitForFunction' => 'doneProcessing === true'
          )
        end
        let(:date) { Date.today.strftime '%-m/%-d/%Y' }

        it { expect(pdf_text_content).to eq "#{date} Hey there http://www.example.net/foo/bar 1/1" }
      end

      context 'when wait for function option is specified with options' do
        let(:url_or_html) do
          <<-HTML
            <html>
              <body></body>

              <script>
                var doneProcessing = false

                function startProcessing() {
                  setTimeout(function() {
                    doneProcessing = true
                    document.body.innerHTML = '<p>Hello, world!</p>';
                  }, 500);
                }
              </script>
            </html>
          HTML
        end
        let(:wait_function_timeout) { 1000 }
        let(:options) do
          basic_header_footer_options.merge(
            'executeScript' => 'startProcessing()',
            'waitForFunction' => 'doneProcessing === true',
            'waitForFunctionOptions' => { "polling": 50, "timeout": wait_function_timeout }
          )
        end
        let(:date) { Date.today.strftime '%-m/%-d/%Y' }

        it { expect(pdf_text_content).to eq "#{date} Hello, world! http://www.example.net/foo/bar 1/1" }

        context 'when waiting for function takes too long' do
          let(:wait_function_timeout) { 100 }

          it 'raises a JavaScript error if waitForFunction fails' do
            expect do
              pdf_text_content
            end.to raise_error Grover::JavaScript::TimeoutError, /waiting for function failed/
          end
        end
      end

      context 'when raise on request failure option is specified' do
        let(:options) { basic_header_footer_options.merge('raiseOnRequestFailure' => true) }
        let(:date) { Date.today.strftime '%-m/%-d/%Y' }

        context 'when a failure occurs it raises an error' do
          let(:url_or_html) do
            <<-HTML
              <html>
                <body>
                  <img src="http://foo.bar/baz.img" />
                </body>
              </html>
            HTML
          end

          it do
            expect do
              convert
            end.to raise_error Grover::JavaScript::RequestFailedError, 'net::ERR_NAME_NOT_RESOLVED at http://foo.bar/baz.img'
          end
        end

        context 'when a 404 occurs it raises an error' do
          let(:url_or_html) do
            <<-HTML
              <html>
                <body>
                  <img src="https://google.com/404.jpg" />
                </body>
              </html>
            HTML
          end

          it do
            expect do
              convert
            end.to raise_error Grover::JavaScript::RequestFailedError, '404 https://google.com/404.jpg'
          end
        end

        context 'when assets have redirects PDFs are generated successfully' do
          it { expect(pdf_text_content).to match "#{date} Google" }
        end

        context 'with images' do
          let(:url_or_html) do
            <<-HTML
              <html>
                <body>
                  <img src="https://placekitten.com/200/200" />
                </body>
              </html>
            HTML
          end

          it do
            _, stream = pdf_reader.pages.first.xobjects.first
            expect(stream.hash[:Subtype]).to eq :Image
          end
        end
      end

      context 'when wait for selector option is specified with options' do
        let(:url_or_html) do
          <<-HTML
            <html>
              <body>
                <p id="loading">Loading</p>
              </body>

              <script>
                setTimeout(function() {
                  document.getElementById('loading').remove()
                }, 100);
              </script>
            </html>
          HTML
        end
        let(:options) do
          basic_header_footer_options.merge(
            'waitForSelector' => '#loading',
            'waitForSelectorOptions' => { 'hidden' => true }
          )
        end
        let(:date) { Date.today.strftime '%-m/%-d/%Y' }

        it { expect(pdf_text_content).to eq "#{date} http://www.example.net/foo/bar 1/1" }
      end

      # Only test `waitForTimeout` if the Puppeteer supports it
      if puppeteer_version_on_or_after? '5.3.0'
        context 'when wait for timeout option is specified' do
          let(:url_or_html) do
            <<-HTML
              <html>
                <body>
                  <p id="loading">Loading</p>
                  <p id="content" style="display: none">Loaded</p>
                </body>
  
                <script>
                  setTimeout(function() {
                    document.getElementById('loading').remove();
                    document.getElementById('content').style.display = 'block';
                  }, 100);
                </script>
              </html>
            HTML
          end
          let(:options) { { 'waitUntil' => 'load' } }

          it { expect(pdf_text_content).to eq 'Loading' }

          context 'when waiting for the content load timeout to occur' do
            let(:options) { { 'waitForTimeout' => 200, 'waitUntil' => 'load' } }

            it { expect(pdf_text_content).to eq 'Loaded' }
          end
        end
      end

      context 'when passing styles and scripts' do
        let(:url_or_html) do
          <<-HTML
            <html>
              <body>
                <h1>Hey there</h1>
                <h2>Konnichiwa</h2>
              </body>
            </html>
          HTML
        end

        context 'when style tag options are specified' do
          let(:options) do
            {
              'styleTagOptions' => [{ 'content' => 'h1 { display: none }' }]
            }
          end

          it { expect(pdf_text_content).to eq 'Konnichiwa' }
        end

        context 'when script tag options are specified' do
          let(:options) do
            {
              'scriptTagOptions' => [{ 'content' => 'document.querySelector("h2").style.display = "none"' }]
            }
          end

          it { expect(pdf_text_content).to eq 'Hey there' }
        end
      end
    end

    context 'when converting to an image' do
      let(:method) { :screenshot }

      let(:image) { MiniMagick::Image.read convert }

      context 'when passing through a valid URL' do
        let(:url_or_html) { 'https://media.gettyimages.com/photos/tabby-cat-selfie-picture-id1151094724?s=2048x2048' }

        # default screenshot is PNG 800w x 600h
        it { expect(convert.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
        it { expect(image.type).to eq 'PNG' }
        it { expect(image.dimensions).to eq [800, 600] }

        # don't really want to rely on pixel testing the website screenshot
        # so we'll check it's mean colour is roughly what we expect
        it do
          expect(image.data.dig('imageStatistics', MiniMagick.imagemagick7? ? 'Overall' : 'all', 'mean').to_f).
            to be_within(1).of(97.7473).  # ImageMagick 6.9.3-1 (version used by Travis CI)
            or be_within(1).of(161.497)   # ImageMagick 6.9.10-84
        end
      end

      context 'when passing through html' do
        let(:url_or_html) { '<html><body style="background-color: blue"></body></html>' }

        it { expect(convert.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
        it { expect(image.type).to eq 'PNG' }
        it { expect(image.dimensions).to eq [800, 600] }
        it { expect(mean_colour_statistics(image)).to eq %w[0 0 255] }
      end

      context 'when passing through clip options to Grover' do
        let(:url_or_html) { '<html><body style="background-color: red"></body></html>' }
        let(:options) { { clip: { x: 0, y: 0, width: 200, height: 100 } } }

        it { expect(convert.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
        it { expect(image.type).to eq 'PNG' }
        it { expect(image.dimensions).to eq [200, 100] }
        it { expect(mean_colour_statistics(image)).to eq %w[255 0 0] }
      end

      context 'when passing through viewport options to Grover' do
        let(:url_or_html) { '<html><body style="background-color: brown"></body></html>' }
        let(:options) { { viewport: { width: 400, height: 500 } } }

        it { expect(convert.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
        it { expect(image.type).to eq 'PNG' }
        it { expect(image.dimensions).to eq [400, 500] }
        it { expect(mean_colour_statistics(image)).to eq %w[165 42 42] }
      end

      # Only test `emulateMediaFeatures` if the Puppeteer supports it
      if puppeteer_version_on_or_after? '2.0.0'
        context 'when passing through `media_features` options' do
          let(:url_or_html) do
            <<~HTML
              <html>
                <head>
                  <style>
                    body { background-color: red; }
                    @media (prefers-color-scheme: light) {
                      body { background-color: green; }
                    }
                    @media (prefers-color-scheme: dark) {
                      body { background-color: blue; }
                    }
                  </style>
                </head>
                <body></body>
              </html>
            HTML
          end
          let(:options) do
            { path: 'foo.png', 'mediaFeatures' => [{ 'name' => 'prefers-color-scheme', 'value' => 'dark' }] }
          end

          it { expect(convert.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
          it { expect(image.type).to eq 'PNG' }
          it { expect(image.dimensions).to eq [800, 600] }
          it { expect(mean_colour_statistics(image)).to eq %w[0 0 255] }
        end
      end

      context 'when specifying type of `png`' do
        let(:url_or_html) { '<html><body style="background-color: green"></body></html>' }
        let(:options) { { type: 'png' } }

        it { expect(convert.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
        it { expect(image.type).to eq 'PNG' }
        it { expect(image.dimensions).to eq [800, 600] }
        it { expect(mean_colour_statistics(image)).to eq %w[0 128 0] }
      end

      context 'when specifying type of `jpeg`' do
        let(:url_or_html) { '<html><body style="background-color: purple"></body></html>' }
        let(:options) { { type: 'jpeg' } }

        it { expect(convert.unpack('C*')).to start_with [0xFF, 0xD8, 0xFF] }
        it { expect(convert[6..9]).to eq 'JFIF' }
        it { expect(convert.unpack('C*')).to end_with [0xFF, 0xD9] }
        it { expect(image.type).to eq 'JPEG' }
        it { expect(image.dimensions).to eq [800, 600] }
        it { expect(mean_colour_statistics(image)).to eq %w[129 0 127] }
      end

      def mean_colour_statistics(image)
        colours = %w[red green blue]
        stats = image.data['channelStatistics']
        colours.map { |colour| stats[colour] || stats[colour.capitalize] }.map { |details| details['mean'].to_s }
      end
    end

    context 'when rendering HTML' do
      let(:method) { :content }

      let(:url_or_html) do
        <<-HTML
          <html>
            <head></head>
            <body>
              <h1>Hey there</h1>
              <h2>Konnichiwa</h2>
            </body>
          </html>
        HTML
      end

      let(:options) do
        {
          'scriptTagOptions' => [{ 'content' => 'document.querySelector("h2").remove()' }]
        }
      end

      it 'returns the rendered HTML' do
        expect(Grover::Utils.squish(convert)).to eq(
          Grover::Utils.squish(
            <<-HTML
              <html><head><script type="">document.querySelector("h2").remove()</script></head>
              <body>
                <h1>Hey there</h1>
              </body></html>
            HTML
          )
        )
      end
    end
  end
end
