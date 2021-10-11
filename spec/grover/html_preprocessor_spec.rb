# frozen_string_literal: true

require 'spec_helper'

describe Grover::HTMLPreprocessor do
  describe '.process' do
    subject(:process) { described_class.process html, root_url, protocol }

    let(:root_url) { 'http://example.com/' }
    let(:protocol) { 'http' }

    context 'when HTML is empty' do
      let(:html) { '' }

      it { is_expected.to eq '' }
    end

    context 'when HTML doesnt have any relative URLs' do
      let(:html) { '<html><body>Some Content</body></html>' }

      it { is_expected.to eq html }
    end

    context 'with host-relative URL with single quotes' do
      let(:html) do
        <<~HTML
          <html>
            <head>
              <link href='/stylesheets/application.css' rel='stylesheet' type='text/css' />
            </head>
            <body>
              <img alt='test' src='/test.png' />
            </body>
          </html>
        HTML
      end

      it do
        expect(process).to eq <<~HTML
          <html>
            <head>
              <link href='http://example.com/stylesheets/application.css' rel='stylesheet' type='text/css' />
            </head>
            <body>
              <img alt='test' src='http://example.com/test.png' />
            </body>
          </html>
        HTML
      end
    end

    context 'with host-relative URL with double quotes' do
      let(:html) { '<link href="/stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />' }

      it do
        expect(process).to eq <<~HTML.delete("\n")
          <link href="http://example.com/stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />
        HTML
      end
    end

    context 'with protocol-relative URL with single quotes' do
      let(:html) do
        "<link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>"
      end

      it do
        expect(process).to eq <<~HTML.delete("\n")
          <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>
        HTML
      end
    end

    context 'with protocol-relative URL with double quotes' do
      let(:html) do
        '<link href="//fonts.googleapis.com/css?family=Open+Sans:400,600" rel="stylesheet" type="text/css">'
      end

      it do
        expect(process).to eq <<~HTML.delete("\n")
          <link href="http://fonts.googleapis.com/css?family=Open+Sans:400,600" rel="stylesheet" type="text/css">
        HTML
      end
    end

    context 'with host-relative root URL' do
      let(:html) { "<a href='/'><img src='/logo.jpg' ></a>" }

      it { is_expected.to eq "<a href='http://example.com/'><img src='http://example.com/logo.jpg' ></a>" }
    end

    context 'when options not set' do
      let(:html) do
        <<~HTML
          <link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>
          <a href='/'><img src='/logo.jpg'></a>
        HTML
      end

      context 'when root_url is nil' do
        let(:root_url) { nil }

        it do
          expect(process).to eq <<~HTML
            <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>
            <a href='/'><img src='/logo.jpg'></a>
          HTML
        end
      end

      context 'when protocol is nil' do
        let(:protocol) { nil }

        it do
          expect(process).to eq <<~HTML
            <link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>
            <a href='http://example.com/'><img src='http://example.com/logo.jpg'></a>
          HTML
        end
      end

      context 'when both root_url and protocol are nil' do
        let(:root_url) { nil }
        let(:protocol) { nil }

        it { is_expected.to eq html }
      end
    end
  end
end
