require 'spec_helper'

describe Grover do
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
      it { expect(new.instance_variable_get('@options')).to eq(page_size: 'A4') }

      context 'with root path specified' do
        let(:options) { { page_size: 'A4', root_path: 'foo/bar/baz' } }

        it { expect(new.instance_variable_get('@url')).to eq 'http://happyfuntimes.com' }
        it { expect(new.instance_variable_get('@root_path')).to eq 'foo/bar/baz' }
        it { expect(new.instance_variable_get('@options')).to eq(page_size: 'A4') }
      end
    end
  end

  describe '#to_pdf' do
    subject(:to_pdf) { described_class.new(url_or_html).to_pdf }

    let(:pdf_reader) { PDF::Reader.new pdf_io }
    let(:pdf_io) { StringIO.new to_pdf }
    let(:pdf_text_content) { Grover::Utils.squish(pdf_reader.pages.first.text) }
    let(:large_text) { '<style>.text { font-size: 18px; }</style>' }

    context 'when passing through a valid URL' do
      let(:url_or_html) { 'https://www.google.com' }

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
      let(:nbsp) { [160].pack('U*') } # &nbsp;

      it { is_expected.to start_with "%PDF-1.4\n" }
      it { expect(pdf_reader.page_count).to eq 1 }
      it { expect(pdf_reader.pages.first.text).to eq "Hey#{nbsp}there" }
    end

    context 'when passing through options to Grover' do
      subject(:to_pdf) { described_class.new(url_or_html, options).to_pdf }

      let(:url_or_html) { '<html><head><title>Paaage</title></head><body><h1>Hey there</h1></body></html>' }

      context 'when options includes A4 page format' do
        let(:options) { { format: 'A4' } }

        it { expect(pdf_reader.pages.first.attributes).to include(MediaBox: [0, 0, 594.95996, 841.91998]) }
      end

      context 'when options includes Letter page format' do
        let(:options) { { format: 'Letter' } }

        it { expect(pdf_reader.pages.first.attributes).to include(MediaBox: [0, 0, 612, 792]) }
      end

      context 'when options include header and footer enabled' do
        let(:options) do
          {
            display_header_footer: true,
            footer_template: large_text
          }
        end

        it do
          date = Date.today.strftime '%-m/%-d/%Y'
          expect(pdf_text_content).to eq "Hey there #{date} Paaage"
        end
      end

      context 'when options override header template' do
        let(:options) do
          {
            display_header_footer: true,
            header_template: 'Excellente',
            footer_template: large_text
          }
        end

        it { expect(pdf_text_content).to eq 'Excellente Hey there' }
      end

      context 'when header template includes the display url marker' do
        let(:options) do
          {
            display_header_footer: true,
            display_url: 'http://www.examples.net/foo/bar',
            header_template: 'abc{{display_url}}def',
            footer_template: large_text
          }
        end

        it do
          expect(pdf_text_content).to(
            eq('abchttp://www.examples.net/foo/bardef Hey there')
          )
        end
      end

      context 'when options override footer template' do
        let(:options) do
          {
            display_header_footer: true,
            display_url: 'http://www.examples.net/foo/bar',
            footer_template: 'great {{display_url}} page',
            header_template: large_text
          }
        end

        it { expect(pdf_text_content).to eq 'Hey there great http://www.examples.net/foo/bar page' }
      end
    end

    context 'when global options are defined' do
      let(:url_or_html) { '<html><body><h1>Hey there</h1></body></html>' }
      let(:options) do
        {
          display_header_footer: true,
          display_url: 'http://www.examples.net/foo/bar',
          header_template: large_text
        }
      end

      before { allow(described_class.configuration).to receive(:options).and_return(options) }

      it { expect(pdf_text_content).to eq 'Hey there http://www.examples.net/foo/bar 1/1' }
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

  describe '#inspect' do
    subject(:inspect) { grover.inspect }

    let(:grover) { described_class.new('http://google.com') }

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
