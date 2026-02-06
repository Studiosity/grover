# frozen_string_literal: true

require 'spec_helper'

describe Grover::DevToolsParser do
  describe '.parse' do
    subject(:parse) { described_class.parse raw_devtools_output }

    context 'when the devtools output is empty' do
      let(:raw_devtools_output) { '' }

      it { is_expected.to eq [] }
    end

    context 'when the devtools output contains a plain string' do
      let(:raw_devtools_output) { 'foo' }

      it { is_expected.to eq ['foo'] }
    end

    context 'when the devtools output contains a multiple lines' do
      let(:raw_devtools_output) do
        <<~OUTPUT
          foo
          bar
        OUTPUT
      end

      it { is_expected.to eq %w[foo bar] }
    end

    context 'when the devtools output contains a multi-line array object' do
      let(:raw_devtools_output) do
        <<~OUTPUT
          foo [
            'bar'
          ]
          baz
        OUTPUT
      end

      it { is_expected.to eq ["foo [ 'bar' ]", 'baz'] }
    end

    context 'when the devtools output contains a malformed multi-line array object' do
      let(:raw_devtools_output) do
        <<~OUTPUT
          foo [
            'bar'
          baz
        OUTPUT
      end

      it { is_expected.to eq ['foo [', "  'bar'", 'baz'] }
    end

    context 'when the devtools output contains a multi-line hash object' do
      let(:raw_devtools_output) do
        <<~OUTPUT
          foo {
            bar: true,
            baz: 1,
            qux: '123'
          }
          baz
        OUTPUT
      end

      it { is_expected.to eq ["foo { bar: true, baz: 1, qux: '123' }", 'baz'] }
    end

    context 'when the devtools output contains a malformed multi-line hash object' do
      let(:raw_devtools_output) do
        <<~OUTPUT
          foo {
            bar: true,
            baz: 1,
          }
          baz
        OUTPUT
      end

      it { is_expected.to eq ['foo {', '  bar: true,', '  baz: 1,', '}', 'baz'] }
    end
  end
end
