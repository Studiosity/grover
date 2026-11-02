# frozen_string_literal: true

require 'spec_helper'
require 'grover/options_builder'

describe Grover::OptionsBuilder do
  subject(:built_options) { described_class.new(options, url_or_html) }

  let(:url_or_html) { 'https://google.com' }
  let(:options) { {} }
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
        'quality' => 91,
        'viewport' => {
          'width' => 100
        }
      )
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

    it { is_expected.to include('footer_template' => %(<div class='text'>Footer with "quotes" in it</div>)) }
  end

  context 'when specifying launch args via meta tags' do
    let(:url_or_html) do
      Grover::Utils.squish(<<-HTML)
        <html>
          <head>
            <meta name="grover-launch_args" content="['--disable-speech-api']" />
          </head>
        </html>
      HTML
    end

    it 'ignores launch_args supplied via meta tags' do
      expect(built_options).not_to have_key('launch_args')
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

    it { is_expected.to include('display_header_footer' => false) }
  end

  context 'when the page contains restricted meta options' do
    let(:url_or_html) do
      Grover::Utils.squish(<<-HTML)
        <html>
          <head>
            <meta name="grover-format" content="A5" />
            <meta name="grover-front_cover_path" content="/some/front-cover-path" />
            <meta name="grover-back_cover_path" content="/some/back-cover-path" />
          </head>
        </html>
      HTML
    end

    it 'only returns global options and safe meta options' do
      expect(built_options).to eq('cache' => false, 'format' => 'A5', 'quality' => 95)
    end

    context 'when `allow_restricted_meta_option` configuration option is set true' do
      before { allow(Grover.configuration).to receive(:allow_restricted_meta_option).and_return true }

      it 'only returns global options, safe meta options and restricted meta options' do
        expect(built_options).to eq(
          'cache' => false,
          'format' => 'A5',
          'quality' => 95,
          'front_cover_path' => '/some/front-cover-path',
          'back_cover_path' => '/some/back-cover-path'
        )
      end
    end

    context 'when `allow_restricted_meta_option` configuration option is set to a proc' do
      before do
        allow(Grover.configuration).to(
          receive(:allow_restricted_meta_option).
            and_return(lambda do |tag_name, value|
              tag_name == 'front_cover_path' && value.start_with?('/some/front-')
            end)
        )
      end

      it 'only returns global options, safe meta options and allowed restricted meta options' do
        expect(built_options).to eq(
          'cache' => false,
          'format' => 'A5',
          'quality' => 95,
          'front_cover_path' => '/some/front-cover-path'
        )
      end
    end
  end

  context 'when the page contains dangerous meta options' do
    let(:url_or_html) do
      Grover::Utils.squish(<<-HTML)
        <html>
          <head>
            <meta name="grover-format" content="A4" />
            <meta name="grover-executable_path" content="/tmp/evil" />
            <meta name="grover-launch_args" content="['--no-sandbox']" />
            <meta name="grover-browser_ws_endpoint" content="ws://attacker:3000" />
            <meta name="grover-path" content="/var/www/public/x.pdf" />
            <meta name="grover-root_path" content="/var/www/public/uploads" />
            <meta name="grover-front_cover_path" content="/admin/export" />
            <meta name="x-grover-executable_path" content="/tmp/evil2" />
            <meta name="grover-allow_file_uri" content="true" />
            <meta name="grover-allow_local_network_access" content="true" />
            <meta name="grover-browser" content="evil" />
            <meta name="grover-bypass_csp" content="true" />
            <meta name="grover-bypass_c_s_p" content="true" />
            <meta name="grover-cache" content="false" />
            <meta name="grover-convert_timeout" content="0" />
            <meta name="grover-debug" content="true" />
            <meta name="grover-evaluate_on_new_document" content="console.log('fail')" />
            <meta name="grover-execute_script" content="console.log('fail')" />
            <meta name="grover-extra_http_headers" content="fail" />
            <meta name="grover-extra_h_t_t_p_headers" content="fail" />
            <meta name="grover-javascript_enabled" content="true" />
            <meta name="grover-java_script_enabled" content="true" />
            <meta name="grover-launch_timeout" content="0" />
            <meta name="grover-raise_on_js_error" content="false" />
            <meta name="grover-raise_on_j_s_error" content="false" />
            <meta name="grover-raise_on_request_failure" content="false" />
            <meta name="grover-request_timeout" content="0" />
            <meta name="grover-style_tag_options" content="https://evil.com/badstyle-xss.css" />
            <meta name="grover-script_tag_options" content="https://evil.com/badscript-xss.css" />
            <meta name="grover-timeout" content="0" />
            <meta name="grover-wait_for_fonts" content="true" />
            <meta name="grover-wait_for_function" content="while(true)" />
            <meta name="grover-wait_for_selector" content="doesnt-exist" />
            <meta name="grover-wait_for_timeout" content="10000000" />
          </head>
        </html>
      HTML
    end

    it 'only returns global options and safe meta options' do
      expect(built_options).to eq('cache' => false, 'format' => 'A4', 'quality' => 95)
    end

    context 'when there is a global option setting one of these unsafe options' do
      let(:global_config) { { root_path: 'global path', 'browser' => 'global browser', format: 'A5' } }

      it 'filters out the unsafe options and returns the safe ones' do
        expect(built_options).to eq('format' => 'A4', 'root_path' => 'global path', 'browser' => 'global browser')
      end
    end

    context 'when there is an instance option setting one of these unsafe options' do
      let(:options) { { root_path: 'instance path', 'browser' => 'instance browser', format: 'A5' } }

      it 'filters out the unsafe options and returns the safe ones' do
        expect(built_options).to eq(
          'format' => 'A4',
          'root_path' => 'instance path',
          'browser' => 'instance browser',
          'cache' => false,
          'quality' => 95
        )
      end
    end

    context 'when the unsafe options are somewhere other than the head' do
      let(:url_or_html) do
        Grover::Utils.squish(<<-HTML)
          <html>
            <body>
              <meta name="grover-format" content="A4" />
              <meta name="grover-root_path" content="/var/www/public/uploads" />
              <h1>Hey there</h1>
            </body>
          </html>
        HTML
      end

      it 'filters out the unsafe options and returns the safe ones' do
        expect(built_options).to eq('format' => 'A4', 'cache' => false, 'quality' => 95)
      end
    end

    context 'when the unsafe meta options are provided in camel-case' do
      let(:url_or_html) do
        Grover::Utils.squish(<<-HTML)
          <html>
            <head>
              <title>Paaage</title>
              <meta name="grover-format" content="A4" />
              <meta name="grover-rootPath" content="fail" />
              <meta name="grover-allowFileUri" content="fail" />
              <meta name="grover-allowLocalNetworkAccess" content="fail" />
              <meta name="grover-browserWsEndpoint" content="fail" />
              <meta name="grover-bypassCSP" content="fail" />
              <meta name="grover-convertTimeout" content="fail" />
              <meta name="grover-evaluateOnNewDocument" content="fail" />
              <meta name="grover-executablePath" content="fail" />
              <meta name="grover-executeScript" content="fail" />
              <meta name="grover-extraHTTPHeaders" content="fail" />
              <meta name="grover-javaScriptEnabled" content="fail" />
              <meta name="grover-launchArgs" content="fail" />
              <meta name="grover-launchTimeout" content="fail" />
              <meta name="grover-raiseOnJSError" content="fail" />
              <meta name="grover-raiseOnRequestFailure" content="fail" />
              <meta name="grover-requestTimeout" content="fail" />
              <meta name="grover-styleTagOptions" content="fail" />
              <meta name="grover-scriptTagOptions" content="fail" />
              <meta name="grover-waitForFonts" content="fail" />
              <meta name="grover-waitForFunction" content="fail" />
              <meta name="grover-waitForSelector" content="fail" />
              <meta name="grover-waitForTimeout" content="fail" />
            </head>
            <body>
              <h1>Hey there</h1>
            </body>
          </html>
        HTML
      end

      it 'filters out the unsafe options and returns the safe ones' do
        expect(built_options).to eq('format' => 'A4', 'cache' => false, 'quality' => 95)
      end
    end
  end

  context 'when the page contains malformed meta options' do
    let(:url_or_html) do
      Grover::Utils.squish(<<-HTML)
        <html>
          <head>
            <meta name="grover-format" content="A3" />
            <meta name="grover-" content="Only the prefix" />
            <meta name="grover--" content="Only a dash" />
            <meta name="grover-_" content="Only an underscore" />
            <meta name="grover-width-" content="Trailing dash" />
            <meta name="grover-height_" content="Trailing underscore" />
            <meta name="grover--hover" content="Leading dash" />
            <meta name="grover-_focus" content="Leading underscore" />
          </head>
        </html>
      HTML
    end

    it 'only returns global options and safe meta options' do
      expect(built_options).to eq('cache' => false, 'format' => 'A3', 'quality' => 95)
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

    it { is_expected.to include('viewport' => { 'height' => 100, 'width' => 200, 'device_scale_factor' => 2.5 }) }
  end
end
