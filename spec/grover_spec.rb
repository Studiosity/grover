# frozen_string_literal: true

require 'spec_helper'

describe Grover do
  let(:grover) { described_class.new(url_or_html, **options) }
  let(:url_or_html) { 'http://google.com' }
  let(:options) { {} }
  let(:processor) { instance_double Grover::Processor }

  describe '.new' do
    subject(:new) { described_class.new('http://google.com') }

    it { expect(new.instance_variable_get('@url')).to eq 'http://google.com' }
    it { expect(new.instance_variable_get('@root_path')).to be_nil }
    it { expect(new.instance_variable_get('@options')).to eq({}) }

    context 'with options passed' do
      subject(:new) { described_class.new('http://happyfuntimes.com', **options) }

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

    context 'when url provided is `nil`' do
      subject(:new) { described_class.new(nil) }

      it { expect(new.instance_variable_get('@url')).to eq '' }
      it { expect(new.instance_variable_get('@root_path')).to be_nil }
      it { expect(new.instance_variable_get('@options')).to eq({}) }
    end
  end

  describe '#to_pdf' do
    subject(:to_pdf) { grover.to_pdf }

    before { allow(Grover::Processor).to receive(:new).with(Dir.pwd).and_return processor }

    it 'calls to Grover::Processor' do
      allow(processor).to receive(:convert).with(:pdf, url_or_html, {}).and_return 'some PDF content'
      expect(processor).to receive(:convert).with(:pdf, url_or_html, {})
      expect(to_pdf).to eq 'some PDF content'
    end

    context 'when path option is specified' do
      subject(:to_pdf) { grover.to_pdf(path) }

      let(:path) { '/foo/bar' }

      it 'calls to Grover::Processor with the path specified' do
        allow(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'path' => '/foo/bar' }).
            and_return('some PDF content')
        )
        expect(processor).to receive(:convert).with(:pdf, url_or_html, { 'path' => '/foo/bar' })
        expect(to_pdf).to eq 'some PDF content'
      end

      context 'when the path provided is not a String' do
        let(:path) { 1234 }

        it 'calls to Grover::Processor without the path specified' do
          allow(processor).to(
            receive(:convert).
              with(:pdf, url_or_html, {}).
              and_return('some PDF content')
          )
          expect(processor).to receive(:convert).with(:pdf, url_or_html, {})
          expect(to_pdf).to eq 'some PDF content'
        end
      end
    end

    context 'when root_path is overridden' do
      let(:options) { { root_path: 'foo/bar/baz' } }

      it 'calls to Grover::Processor with overridden path' do
        allow(Grover::Processor).to receive(:new).with('foo/bar/baz').and_return processor
        allow(processor).to receive(:convert).with(:pdf, url_or_html, {}).and_return 'some PDF content'
        expect(Grover::Processor).to receive(:new).with('foo/bar/baz')
        expect(processor).to receive(:convert).with(:pdf, url_or_html, {})
        expect(to_pdf).to eq 'some PDF content'
      end
    end

    context 'when global options are defined' do
      let(:global_options) { { header_template: 'Some header' } }

      before { allow(described_class.configuration).to receive(:options).and_return global_options }

      it 'builds options and passes them through to the processor' do
        allow(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'headerTemplate' => 'Some header' }).
            and_return('some PDF content')
        )
        expect(processor).to receive(:convert).with(:pdf, url_or_html, { 'headerTemplate' => 'Some header' })
        expect(to_pdf).to eq 'some PDF content'
      end

      context 'when global options include front and back cover paths' do
        let(:global_options) { { front_cover_path: '/front', back_cover_path: '/back' } }

        it 'excludes front and back cover paths from options passed to processor' do
          allow(processor).to receive(:convert).with(:pdf, url_or_html, {}).and_return 'some PDF content'
          expect(processor).to receive(:convert).with(:pdf, url_or_html, {})
          expect(to_pdf).to eq 'some PDF content'
          expect(grover.front_cover_path).to eq '/front'
          expect(grover.back_cover_path).to eq '/back'
        end
      end

      context 'when instance options are provided' do
        let(:options) { { header_template: 'instance header', footer_template: 'instance footer' } }

        it 'builds options, overriding global options, and passes them through to the processor' do
          allow(processor).to(
            receive(:convert).
              with(:pdf, url_or_html, { 'headerTemplate' => 'instance header', 'footerTemplate' => 'instance footer' }).
              and_return('some PDF content')
          )
          expect(processor).to(
            receive(:convert).
              with(:pdf, url_or_html, { 'headerTemplate' => 'instance header', 'footerTemplate' => 'instance footer' })
          )
          expect(to_pdf).to eq 'some PDF content'
        end
      end
    end

    context 'when options include front and back cover paths' do
      let(:options) { { front_cover_path: '/front', back_cover_path: '/back' } }

      it 'excludes front and back cover paths from options passed to processor' do
        allow(processor).to receive(:convert).with(:pdf, url_or_html, {}).and_return 'some PDF content'
        expect(processor).to receive(:convert).with(:pdf, url_or_html, {})
        expect(to_pdf).to eq 'some PDF content'
        expect(grover.front_cover_path).to eq '/front'
        expect(grover.back_cover_path).to eq '/back'
      end
    end

    context 'when the page contains meta options with escaped content' do
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

      it 'builds options and passes them through to the processor' do
        allow(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'footerTemplate' => "<div class='text'>Footer with \"quotes\" in it</div>" }).
            and_return('some PDF content')
        )
        expect(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'footerTemplate' => "<div class='text'>Footer with \"quotes\" in it</div>" })
        )
        expect(to_pdf).to eq 'some PDF content'
      end
    end

    context 'when specifying an array of launch args in meta tags' do
      let(:url_or_html) do
        Grover::Utils.squish(<<-HTML)
        <html>
          <head>
            <meta name="grover-launch_args" content="['--disable-speech-api']" />
          </head>
        </html>
        HTML
      end

      it 'builds options and passes them through to the processor' do
        allow(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'launchArgs' => ['--disable-speech-api'] }).
            and_return('some PDF content')
        )
        expect(processor).to receive(:convert).with(:pdf, url_or_html, { 'launchArgs' => ['--disable-speech-api'] })
        expect(to_pdf).to eq 'some PDF content'
      end
    end

    context 'when the page contains meta options with boolean content' do
      let(:url_or_html) do
        Grover::Utils.squish(<<-HTML)
        <html>
          <head>
            <meta name="grover-display_header_footer" content='false' />
          </head>
        </html>
        HTML
      end

      it 'builds options and passes them through to the processor' do
        allow(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'displayHeaderFooter' => false }).
            and_return('some PDF content')
        )
        expect(processor).to receive(:convert).with(:pdf, url_or_html, { 'displayHeaderFooter' => false })
        expect(to_pdf).to eq 'some PDF content'
      end
    end

    context 'when passing viewport options to Grover with meta tags' do
      let(:url_or_html) do
        Grover::Utils.squish(<<-HTML)
          <html>
            <head>
              <title>Paaage</title>
              <meta name="grover-viewport-height" content="100" />
              <meta name="grover-viewport-width" content="200" />
              <meta name="grover-viewport-device_scale_factor" content="2.5" />
            </head>
          </html>
        HTML
      end

      it 'builds options and passes them through to the processor' do
        allow(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'viewport' => { 'height' => 100, 'width' => 200, 'deviceScaleFactor' => 2.5 } }).
            and_return('some PDF content')
        )
        expect(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'viewport' => { 'height' => 100, 'width' => 200, 'deviceScaleFactor' => 2.5 } })
        )
        expect(to_pdf).to eq 'some PDF content'
      end
    end

    context 'when passing extra HTTP headers' do
      let(:options) { { extra_http_headers: { 'Foo' => 'Bar', 'baz' => 'Qux' } } }

      it 'does not transform the header keys' do
        allow(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'extraHTTPHeaders' => { 'Foo' => 'Bar', 'baz' => 'Qux' } }).
            and_return('some PDF content')
        )
        expect(processor).to(
          receive(:convert).
            with(:pdf, url_or_html, { 'extraHTTPHeaders' => { 'Foo' => 'Bar', 'baz' => 'Qux' } })
        )
        expect(to_pdf).to eq 'some PDF content'
      end
    end
  end

  describe '#screenshot' do
    subject(:screenshot) { grover.screenshot }

    before { allow(Grover::Processor).to receive(:new).with(Dir.pwd).and_return processor }

    it 'calls to Grover::Processor' do
      allow(processor).to receive(:convert).with(:screenshot, url_or_html, {}).and_return 'some image content'
      expect(processor).to receive(:convert).with(:screenshot, url_or_html, {})
      expect(screenshot).to eq 'some image content'
    end

    context 'when path option is specified' do
      subject(:screenshot) { grover.screenshot(path: '/foo/bar') }

      it 'calls to Grover::Processor with the path specified' do
        allow(processor).to(
          receive(:convert).
            with(:screenshot, url_or_html, { 'path' => '/foo/bar' }).
            and_return('some image content')
        )
        expect(processor).to receive(:convert).with(:screenshot, url_or_html, { 'path' => '/foo/bar' })
        expect(screenshot).to eq 'some image content'
      end
    end

    context 'when format option is specified' do
      subject(:screenshot) { grover.screenshot(format: format) }

      context 'when format is png' do
        let(:format) { 'png' }

        it 'calls to Grover::Processor with the type specified' do
          allow(processor).to(
            receive(:convert).
              with(:screenshot, url_or_html, { 'type' => 'png' }).
              and_return('some image content')
          )
          expect(processor).to receive(:convert).with(:screenshot, url_or_html, { 'type' => 'png' })
          expect(screenshot).to eq 'some image content'
        end
      end

      context 'when format is jpeg' do
        let(:format) { 'jpeg' }

        it 'calls to Grover::Processor with the type specified' do
          allow(processor).to(
            receive(:convert).
              with(:screenshot, url_or_html, { 'type' => 'jpeg' }).
              and_return('some image content')
          )
          expect(processor).to receive(:convert).with(:screenshot, url_or_html, { 'type' => 'jpeg' })
          expect(screenshot).to eq 'some image content'
        end
      end

      context 'when format is bmp' do
        let(:format) { 'bmp' }

        it 'calls to Grover::Processor without the type specified' do
          allow(processor).to receive(:convert).with(:screenshot, url_or_html, {}).and_return 'some image content'
          expect(processor).to receive(:convert).with(:screenshot, url_or_html, {})
          expect(screenshot).to eq 'some image content'
        end
      end
    end

    context 'when root_path is overridden' do
      let(:options) { { root_path: 'foo/bar/baz' } }

      it 'calls to Grover::Processor with overridden path' do
        allow(Grover::Processor).to receive(:new).with('foo/bar/baz').and_return processor
        allow(processor).to receive(:convert).with(:screenshot, url_or_html, {}).and_return 'some image content'
        expect(Grover::Processor).to receive(:new).with('foo/bar/baz')
        expect(processor).to receive(:convert).with(:screenshot, url_or_html, {})
        expect(screenshot).to eq 'some image content'
      end
    end

    context 'when global options are defined' do
      let(:global_options) { { header_template: 'Some header' } }

      before { allow(described_class.configuration).to receive(:options).and_return global_options }

      it 'builds options and passes them through to the processor' do
        allow(processor).to(
          receive(:convert).
            with(:screenshot, url_or_html, { 'headerTemplate' => 'Some header' }).
            and_return('some image content')
        )
        expect(processor).to receive(:convert).with(:screenshot, url_or_html, { 'headerTemplate' => 'Some header' })
        expect(screenshot).to eq 'some image content'
      end

      context 'when global options include front and back cover paths' do
        let(:global_options) { { front_cover_path: '/front', back_cover_path: '/back' } }

        it 'excludes front and back cover paths from options passed to processor' do
          allow(processor).to receive(:convert).with(:screenshot, url_or_html, {}).and_return 'some image content'
          expect(processor).to receive(:convert).with(:screenshot, url_or_html, {})
          expect(screenshot).to eq 'some image content'
          expect(grover.front_cover_path).to eq '/front'
          expect(grover.back_cover_path).to eq '/back'
        end
      end

      context 'when instance options are provided' do
        let(:options) { { header_template: 'instance header', footer_template: 'instance footer' } }

        it 'builds options, overriding global options, and passes them through to the processor' do
          allow(processor).to(
            receive(:convert).
              with(
                :screenshot,
                url_or_html,
                { 'headerTemplate' => 'instance header', 'footerTemplate' => 'instance footer' }
              ).
              and_return('some image content')
          )
          expect(processor).to(
            receive(:convert).
              with(
                :screenshot,
                url_or_html,
                { 'headerTemplate' => 'instance header', 'footerTemplate' => 'instance footer' }
              )
          )
          expect(screenshot).to eq 'some image content'
        end
      end
    end

    context 'when options include front and back cover paths' do
      let(:options) { { front_cover_path: '/front', back_cover_path: '/back' } }

      it 'excludes front and back cover paths from options passed to processor' do
        allow(processor).to receive(:convert).with(:screenshot, url_or_html, {}).and_return 'some image content'
        expect(processor).to receive(:convert).with(:screenshot, url_or_html, {})
        expect(screenshot).to eq 'some image content'
        expect(grover.front_cover_path).to eq '/front'
        expect(grover.back_cover_path).to eq '/back'
      end
    end

    context 'when passing viewport options to Grover with meta tags' do
      let(:url_or_html) do
        Grover::Utils.squish(<<-HTML)
          <html>
            <head>
              <title>Paaage</title>
              <meta name="grover-viewport-height" content="100" />
              <meta name="grover-viewport-width" content="200" />
              <meta name="grover-viewport-device_scale_factor" content="2.5" />
            </head>
          </html>
        HTML
      end

      it 'builds options and passes them through to the processor' do
        allow(processor).to(
          receive(:convert).
            with(
              :screenshot,
              url_or_html,
              { 'viewport' => { 'height' => 100, 'width' => 200, 'deviceScaleFactor' => 2.5 } }
            ).
            and_return('some image content')
        )
        expect(processor).to(
          receive(:convert).
            with(
              :screenshot,
              url_or_html,
              { 'viewport' => { 'height' => 100, 'width' => 200, 'deviceScaleFactor' => 2.5 } }
            )
        )
        expect(screenshot).to eq 'some image content'
      end
    end
  end

  describe '#to_png' do
    subject(:to_png) { grover.to_png }

    before { allow(Grover::Processor).to receive(:new).with(Dir.pwd).and_return processor }

    it 'calls to Grover::Processor' do
      allow(processor).to(
        receive(:convert).
          with(:screenshot, url_or_html, { 'type' => 'png' }).
          and_return('some PNG content')
      )
      expect(processor).to receive(:convert).with(:screenshot, url_or_html, { 'type' => 'png' })
      expect(to_png).to eq 'some PNG content'
    end

    context 'when path option is specified' do
      subject(:to_png) { grover.to_png('/foo/bar') }

      it 'calls to Grover::Processor with the path specified' do
        allow(processor).to(
          receive(:convert).
            with(:screenshot, url_or_html, { 'path' => '/foo/bar', 'type' => 'png' }).
            and_return('some PNG content')
        )
        expect(processor).to receive(:convert).with(:screenshot, url_or_html, { 'path' => '/foo/bar', 'type' => 'png' })
        expect(to_png).to eq 'some PNG content'
      end
    end
  end

  describe '#to_jpeg' do
    subject(:to_jpeg) { grover.to_jpeg }

    before { allow(Grover::Processor).to receive(:new).with(Dir.pwd).and_return processor }

    it 'calls to Grover::Processor' do
      allow(processor).to(
        receive(:convert).
          with(:screenshot, url_or_html, { 'type' => 'jpeg' }).
          and_return('some JPG content')
      )
      expect(processor).to receive(:convert).with(:screenshot, url_or_html, { 'type' => 'jpeg' })

      expect(to_jpeg).to eq 'some JPG content'
    end

    context 'when path option is specified' do
      subject(:to_jpeg) { grover.to_jpeg('/foo/bar') }

      it 'calls to Grover::Processor with the path specified' do
        allow(processor).to(
          receive(:convert).
            with(:screenshot, url_or_html, { 'path' => '/foo/bar', 'type' => 'jpeg' }).
            and_return('some JPG content')
        )
        expect(processor).to receive(:convert).with(:screenshot, url_or_html,
                                                    { 'path' => '/foo/bar', 'type' => 'jpeg' })
        expect(to_jpeg).to eq 'some JPG content'
      end
    end
  end

  describe '#to_html' do
    subject(:to_html) { grover.to_html }

    let(:expected_html) { '<html><body>Some HTML</body></html>' }

    before { allow(Grover::Processor).to receive(:new).with(Dir.pwd).and_return processor }

    it 'calls to Grover::Processor' do
      allow(processor).to receive(:convert).with(:content, url_or_html, {}).and_return expected_html
      expect(processor).to receive(:convert).with(:content, url_or_html, {})
      expect(to_html).to eq expected_html
    end
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

    it { is_expected.to be false }

    context 'when option specified' do
      let(:options) { { front_cover_path: '/baz' } }

      it { is_expected.to be true }
    end

    context 'when the option isnt a path' do
      let(:options) { { front_cover_path: 'http://example.com/baz' } }

      it { is_expected.to be false }
    end
  end

  describe '#show_back_cover?' do
    subject(:show_back_cover?) { grover.show_back_cover? }

    it { is_expected.to be false }

    context 'when option specified' do
      let(:options) { { back_cover_path: '/baz' } }

      it { is_expected.to be true }
    end

    context 'when the option isnt a path' do
      let(:options) { { back_cover_path: 'http://example.com/baz' } }

      it { is_expected.to be false }
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
end
