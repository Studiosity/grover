# frozen_string_literal: true

require 'spec_helper'

describe Grover do
  let(:grover) { described_class.new(url_or_html, options) }
  let(:url_or_html) { 'http://google.com' }
  let(:options) { {} }

  describe '.new' do
    subject(:new) { described_class.new('http://google.com') }

    it { expect(new.instance_variable_get('@url')).to eq 'http://google.com' }
    it { expect(new.instance_variable_get('@root_path')).to be_nil }
    it { expect(new.instance_variable_get('@options')).to eq({}) }

    context 'with options passed' do
      subject(:new) { described_class.new('http://happyfuntimes.com', options) }

      let(:options) { { page_size: 'A4' } }

      it { expect(new.instance_variable_get('@url')).to eq 'http://happyfuntimes.com' }
      it { expect(new.instance_variable_get('@root_path')).to be_nil }
      it { expect(new.instance_variable_get('@options')).to eq('page_size' => 'A4') }

      context 'with root path specified' do
        let(:options) { { page_size: 'A4', root_path: 'foo/bar/baz' } }

        it { expect(new.instance_variable_get('@url')).to eq 'http://happyfuntimes.com' }
        it { expect(new.instance_variable_get('@root_path')).to eq 'foo/bar/baz' }
        it { expect(new.instance_variable_get('@options')).to eq('page_size' => 'A4') }
      end
    end
  end

  describe '#to_pdf' do
    subject(:to_pdf) { grover.to_pdf }

    let(:pdf_reader) { PDF::Reader.new pdf_io }
    let(:pdf_io) { StringIO.new to_pdf }
    let(:pdf_text_content) { Grover::Utils.squish(pdf_reader.pages.first.text) }
    let(:large_text) { '<style>.text { font-size: 14px; }</style>' }
    let(:default_header) { Grover::DEFAULT_HEADER_TEMPLATE }
    let(:basic_header_footer_options) do
      {
        display_header_footer: true,
        display_url: 'http://www.example.net/foo/bar',
        margin: {
          top: '1in',
          bottom: '1in'
        }
      }
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

      it do
        expect do
          to_pdf
        end.to raise_error Schmooze::JavaScript::Error, %r{net::ERR_NAME_NOT_RESOLVED at https://fake.invalid}
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

      context 'when the page contains valid meta options' do
        let(:url_or_html) do
          Grover::Utils.squish(<<-HTML)
            <html>
              <head>
                <title>Paaage</title>
                <meta name="grover-format" content="A3" />
              </head>
              <body>
                <h1>Hey there</h1>
              </body>
            </html>
          HTML
        end

        # For some reason, the Mac platform results in a weird page height (not double the A4 width)
        if /darwin/ =~ RUBY_PLATFORM
          it { expect(pdf_reader.pages.first.attributes).to include(MediaBox: [0, 0, 841.91998, 1188]) }
        else
          it { expect(pdf_reader.pages.first.attributes).to include(MediaBox: [0, 0, 841.91998, 1189.91992]) }
        end
      end

      context 'when the page contains meta options with escaped content' do
        let(:options) { basic_header_footer_options.merge(header_template: large_text) }
        let(:url_or_html) do
          Grover::Utils.squish(<<-HTML)
            <html>
              <head>
                <meta name="grover-footer_template"
                      content="<div class='text'>Footer with &quot;quotes&quot; in it</div>" />
              </head>
              <body>
                <h1>Hey there</h1>
              </body>
            </html>
          HTML
        end

        it { expect(pdf_text_content).to eq 'Hey there Footer with "quotes" in it' }
      end

      context 'when the page contains a line starting with `http`' do
        let(:options) { basic_header_footer_options.merge(header_template: large_text) }
        let(:url_or_html) do
          <<~HTML
            <html>
              <head>
                <meta name="grover-footer_template" content="<div class='text'>Footer content</div>" />
              </head>
              <body>
                <h1>Hey there</h1>
            http://example.com
              </body>
            </html>
          HTML
        end

        it { expect(pdf_text_content).to eq 'Hey there http://example.com Footer content' }
      end

      context 'when the page contains meta options with boolean content' do
        let(:options) { basic_header_footer_options.merge(header_template: 'We dont expect to see this...') }
        let(:url_or_html) do
          Grover::Utils.squish(<<-HTML)
            <html>
              <head>
                <meta name="grover-display_header_footer" content='false' />
              </head>
              <body>
                <h1>Hey there</h1>
              </body>
            </html>
          HTML
        end

        it { expect(pdf_text_content).to eq 'Hey there' }
      end

      context 'when the page contains invalid meta options' do
        let(:url_or_html) do
          Grover::Utils.squish(<<-HTML)
            <html>
              <head>
                <title>Paaage</title>
                <meta name="grover-margin-top" content="totes-invalid" />
              </head>
              <body>
                <h1>Hey there</h1>
              </body>
            </html>
          HTML
        end

        it do
          expect do
            to_pdf
          end.to raise_error Schmooze::JavaScript::Error, /Failed to parse parameter value: totes-invalid/
        end
      end

      context 'when options include header and footer enabled' do
        let(:options) { basic_header_footer_options.merge(header_template: "#{large_text}#{default_header}") }

        it do
          date = Date.today.strftime '%-m/%-d/%Y'
          expect(pdf_text_content).to eq "#{date} Paaage Hey there http://www.example.net/foo/bar 1/1"
        end
      end

      context 'when options override header template' do
        let(:options) do
          basic_header_footer_options.merge(header_template: "#{large_text}<div class='text'>Excellente</div>")
        end

        it { expect(pdf_text_content).to eq 'Excellente Hey there http://www.example.net/foo/bar 1/1' }
      end

      context 'when header template includes the display url marker' do
        let(:options) do
          basic_header_footer_options.merge(
            header_template: "#{large_text}<div class='text'>abc<span class='url'></span>def</div>"
          )
        end

        it do
          expect(pdf_text_content).to(
            eq('abchttp://www.example.net/foo/bardef Hey there http://www.example.net/foo/bar 1/1')
          )
        end
      end

      context 'when options override footer template' do
        let(:options) do
          basic_header_footer_options.merge(
            footer_template: "#{large_text}<div class='text'>great <span class='url'></span> page</div>"
          )
        end

        it do
          date = Date.today.strftime '%-m/%-d/%Y'
          expect(pdf_text_content).to eq "#{date} Paaage Hey there great http://www.example.net/foo/bar page"
        end
      end

      context 'when display_url option is not provided' do
        let(:options) { basic_header_footer_options.tap { |hash| hash.delete(:display_url) } }

        it 'uses the default `example.com` for the footer URL' do
          date = Date.today.strftime '%-m/%-d/%Y'
          expect(pdf_text_content).to eq "#{date} Paaage Hey there http://example.com/ 1/1"
        end
      end

      context 'when passing through launch params' do
        let(:options) { { launch_args: launch_args } }
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

        context 'when disabling speech API via launch params in meta tags' do
          let(:head) { %(<meta name="grover-launch_args" content="['--disable-speech-api']" />) }

          it { expect(pdf_text_content).to eq 'Speech recognition is not supported' }
        end
      end

      context 'when passing through wait_until option' do
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

        context 'when setting wait_until option to load' do
          let(:options) { { wait_until: 'load' } }

          it { expect(pdf_text_content).to eq 'Delayed JavaScript did not run' }
        end
      end
    end

    context 'when global options are defined' do
      let(:url_or_html) { '<html><body><h1>Hey there</h1></body></html>' }
      let(:options) { basic_header_footer_options.merge(header_template: large_text) }

      before { allow(described_class.configuration).to receive(:options).and_return(options) }

      it { expect(pdf_text_content).to eq 'Hey there http://www.example.net/foo/bar 1/1' }
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

      context 'with emulate_media set to `screen`' do
        before { allow(described_class.configuration).to receive(:options).and_return(emulate_media: 'screen') }

        it { expect(pdf_text_content).to eq 'Hey there This should only display for screen media' }
      end
    end
  end

  describe '#screenshot' do
    subject(:screenshot) { grover.screenshot }

    let(:image) { MiniMagick::Image.read screenshot }

    context 'when passing through a valid URL' do
      let(:url_or_html) { 'https://www.google.com/?gl=us' }

      # default screenshot is PNG 800w x 600h
      it { expect(screenshot.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
      it { expect(image.type).to eq 'PNG' }
      it { expect(image.dimensions).to eq [800, 600] }

      # don't really want to rely on pixel testing the website screenshot
      # so we'll check it's mean colour is roughly what we expect
      it { expect(image.data.dig('imageStatistics', 'all', 'mean').to_f).to be_within(5).of 165 }
    end

    context 'when passing through html' do
      let(:url_or_html) { '<html><body style="background-color: blue"></body></html>' }

      it { expect(screenshot.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
      it { expect(image.type).to eq 'PNG' }
      it { expect(image.dimensions).to eq [800, 600] }
      it { expect(mean_colour_statistics(image)).to eq %w[0 0 255] }
    end

    context 'when passing through clip options to Grover' do
      let(:url_or_html) { '<html><body style="background-color: red"></body></html>' }
      let(:options) { { clip: { x: 0, y: 0, width: 200, height: 100 } } }

      it { expect(screenshot.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
      it { expect(image.type).to eq 'PNG' }
      it { expect(image.dimensions).to eq [200, 100] }
      it { expect(mean_colour_statistics(image)).to eq %w[255 0 0] }
    end

    context 'when passing through viewport options to Grover' do
      let(:url_or_html) { '<html><body style="background-color: brown"></body></html>' }
      let(:options) { { viewport: { width: 400, height: 500 } } }

      it { expect(screenshot.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
      it { expect(image.type).to eq 'PNG' }
      it { expect(image.dimensions).to eq [400, 500] }
      it { expect(mean_colour_statistics(image)).to eq %w[165 42 42] }
    end
  end

  describe '#to_png' do
    subject(:to_png) { grover.to_png }

    let(:image) { MiniMagick::Image.read to_png }
    let(:url_or_html) { '<html><body style="background-color: green"></body></html>' }

    it { expect(to_png.unpack('C*')).to start_with "\x89PNG\r\n\x1A\n".unpack('C*') }
    it { expect(image.type).to eq 'PNG' }
    it { expect(image.dimensions).to eq [800, 600] }
    it { expect(mean_colour_statistics(image)).to eq %w[0 128 0] }
  end

  describe '#to_jpeg' do
    subject(:to_jpeg) { grover.to_jpeg }

    let(:image) { MiniMagick::Image.read to_jpeg }
    let(:url_or_html) { '<html><body style="background-color: purple"></body></html>' }

    it { expect(to_jpeg.unpack('C*')).to start_with [0xFF, 0xD8, 0xFF] }
    it { expect(to_jpeg[6..9]).to eq 'JFIF' }
    it { expect(to_jpeg.unpack('C*')).to end_with [0xFF, 0xD9] }
    it { expect(image.type).to eq 'JPEG' }
    it { expect(image.dimensions).to eq [800, 600] }
    it { expect(mean_colour_statistics(image)).to eq %w[129 0 127] }
  end

  describe '#front_cover_path' do
    subject(:front_cover_path) { grover.front_cover_path }

    it { is_expected.to be_nil }

    context 'when option specified in global configuration' do
      before { allow(described_class.configuration).to receive(:options).and_return(front_cover_path: '/foo/bar') }

      it { is_expected.to eq '/foo/bar' }
    end

    context 'when option specified in initialiser options' do
      let(:options) { { front_cover_path: '/baz' } }

      it { is_expected.to eq '/baz' }
    end

    context 'when passed through via meta tag' do
      let(:url_or_html) do
        Grover::Utils.squish(<<-HTML)
          <html>
            <head>
              <title>Paaage</title>
              <meta name="grover-front_cover_path" content="/meta/path" />
            </head>
            <body>
              <h1>Hey there</h1>
            </body>
          </html>
        HTML
      end

      it { is_expected.to eq '/meta/path' }
    end
  end

  describe '#back_cover_path' do
    subject(:back_cover_path) { grover.back_cover_path }

    it { is_expected.to be_nil }

    context 'when option specified in global configuration' do
      before { allow(described_class.configuration).to receive(:options).and_return(back_cover_path: '/foo/bar') }

      it { is_expected.to eq '/foo/bar' }
    end

    context 'when option specified in initialiser options' do
      let(:options) { { back_cover_path: '/baz' } }

      it { is_expected.to eq '/baz' }
    end

    context 'when passed through via meta tag' do
      let(:url_or_html) do
        Grover::Utils.squish(<<-HTML)
          <html>
            <head>
              <title>Paaage</title>
              <meta name="grover-back_cover_path" content="/meta/path" />
            </head>
            <body>
              <h1>Hey there</h1>
            </body>
          </html>
        HTML
      end

      it { is_expected.to eq '/meta/path' }
    end
  end

  describe '#show_front_cover?' do
    subject(:show_front_cover?) { grover.show_front_cover? }

    it { is_expected.to eq false }

    context 'when option specified' do
      let(:options) { { front_cover_path: '/baz' } }

      it { is_expected.to eq true }
    end

    context 'when the option isnt a path' do
      let(:options) { { front_cover_path: 'http://example.com/baz' } }

      it { is_expected.to eq false }
    end
  end

  describe '#show_back_cover?' do
    subject(:show_back_cover?) { grover.show_back_cover? }

    it { is_expected.to eq false }

    context 'when option specified' do
      let(:options) { { back_cover_path: '/baz' } }

      it { is_expected.to eq true }
    end

    context 'when the option isnt a path' do
      let(:options) { { back_cover_path: 'http://example.com/baz' } }

      it { is_expected.to eq false }
    end
  end

  describe '#inspect' do
    subject(:inspect) { grover.inspect }

    it { is_expected.to eq "#<Grover:0x#{grover.object_id} @url=\"http://google.com\">" }
  end

  describe '.configuration' do
    subject(:configuration) { described_class.configuration }

    it { is_expected.to be_a Grover::Configuration }
  end

  describe '.configure' do
    it { expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.configuration) }
  end

  def mean_colour_statistics(image)
    %w[red green blue].map { |colour| image.data.dig('channelStatistics', colour, 'mean') }
  end
end
