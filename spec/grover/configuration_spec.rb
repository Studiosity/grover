# frozen_string_literal: true

require 'spec_helper'

describe Grover::Configuration do
  subject(:configuration) { described_class.new }

  it 'sets default for options' do
    expect(configuration.options).to eq({})
  end

  it 'allows other options to be assigned' do
    configuration.options = { foo: 'bar' }
    expect(configuration.options[:foo]).to eq 'bar'
  end

  describe '#meta_tag_prefix' do
    subject(:meta_tag_prefix) { configuration.meta_tag_prefix }

    it { is_expected.to eq 'grover-' }

    context 'when configured differently' do
      before { configuration.meta_tag_prefix = 'fooPrefix-' }

      it { is_expected.to eq 'fooPrefix-' }
    end
  end

  describe '#root_url' do
    subject(:root_url) { configuration.root_url }

    it { is_expected.to be_nil }

    context 'when configured differently' do
      before { configuration.root_url = 'https://my.domain' }

      it { is_expected.to eq 'https://my.domain' }
    end
  end

  describe '#ignore_path' do
    subject(:ignore_path) { configuration.ignore_path }

    it { is_expected.to be_nil }

    context 'when configured differently' do
      before { configuration.ignore_path = '/foo/bar' }

      it { is_expected.to eq '/foo/bar' }
    end
  end

  describe '#use_pdf_middleware' do
    subject(:use_pdf_middleware) { configuration.use_pdf_middleware }

    it { is_expected.to be true }

    context 'when configured differently' do
      before { configuration.use_pdf_middleware = false }

      it { is_expected.to be false }
    end
  end

  describe '#use_png_middleware' do
    subject(:use_png_middleware) { configuration.use_png_middleware }

    it { is_expected.to be false }

    context 'when configured differently' do
      before { configuration.use_png_middleware = true }

      it { is_expected.to be true }
    end
  end

  describe '#use_jpeg_middleware' do
    subject(:use_jpeg_middleware) { configuration.use_jpeg_middleware }

    it { is_expected.to be false }

    context 'when configured differently' do
      before { configuration.use_jpeg_middleware = true }

      it { is_expected.to be true }
    end
  end

  describe '#node_env_vars' do
    subject(:node_env_vars) { configuration.node_env_vars }

    it { is_expected.to eq({}) }

    context 'when configured differently' do
      before { configuration.node_env_vars = { 'LD_PRELOAD' => '' } }

      it { is_expected.to eq({ 'LD_PRELOAD' => '' }) }
    end
  end

  describe '#allow_file_uris' do
    subject(:allow_file_uris) { configuration.allow_file_uris }

    it { is_expected.to be false }

    context 'when configured differently' do
      before { configuration.allow_file_uris = true }

      it { is_expected.to be true }
    end
  end
end
