# frozen_string_literal: true

require 'spec_helper'
require 'grover/options_builder'

describe Grover::OptionsBuilder do
  subject(:built_options) { described_class.new(options, url_or_html) }

  let(:url_or_html) { 'https://google.com' }
  let(:options) {}
  let(:global_config) { { cache: false, quality: 95 } }

  before { allow(Grover.configuration).to receive(:options).and_return(global_config) }

  context 'when there are options passed in' do
    let(:options) { { viewport: { width: 400, height: 500 } } }

    it 'combines the global config with the passed-in options' do
      expect(built_options).to eq(
        'cache' => false,
        'quality' => 95,
        'viewport' => {
          'width' => 400,
          'height' => 500
        }
      )
    end
  end

  context 'when the passed-in options match the global config' do
    let(:options) { { cache: true, quality: 82 } }

    it 'overrides the global values with the passed-in options' do
      expect(built_options).to eq('cache' => true, 'quality' => 82)
    end
  end

  context 'when the page contains meta options' do
    let(:url_or_html) do
      Grover::Utils.squish(<<-HTML)
        <html>
          <head>
            <title>Paaage</title>
            <meta name="grover-viewport-height" content="100" />
            <meta name="grover-viewport-width" content="200" />
            <meta name="grover-viewport-device_scale_factor" content="2.5" />
          </head>
          <body>
            <h1>Hey there</h1>
          </body>
        </html>
      HTML
    end
    let(:options) { { wait_until: 'load' } }

    it 'combines the meta options with the global config and passed-in options' do
      expect(built_options).to eq(
        'cache' => false,
        'quality' => 95,
        'wait_until' => 'load',
        'viewport' => {
          'width' => 200,
          'height' => 100,
          'device_scale_factor' => 2.5
        }
      )
    end
  end

  context 'when the meta options match global and passed-in options' do
    let(:url_or_html) do
      Grover::Utils.squish(<<-HTML)
        <html>
          <head>
            <title>Paaage</title>
            <meta name="grover-quality" content="91" />
            <meta name="grover-viewport-width" content="100" />
          </head>
          <body>
            <h1>Hey there</h1>
          </body>
        </html>
      HTML
    end
    let(:options) { { viewport: { width: 200 } } }

    it 'overrides the global and passed-in options with the meta options' do
      expect(built_options).to eq(
        'cache' => false,
        'quality' => '91',
        'viewport' => {
          'width' => 100
        }
      )
    end
  end
end
