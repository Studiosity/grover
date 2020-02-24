# frozen_string_literal: true

require 'spec_helper'
require 'grover/options_fixer'

describe Grover::OptionsFixer do
  subject(:fixed_options) { described_class.new(options).run }

  context 'when a boolean option is "false"' do
    let(:options) { { 'display_header_footer' => 'false' } }

    it 'converts the options to a false literal' do
      expect(fixed_options['display_header_footer']).to be false
    end
  end

  context 'when a boolean option is "FALSE"' do
    let(:options) { { 'display_header_footer' => 'FALSE' } }

    it 'converts the option to a false literal' do
      expect(fixed_options['display_header_footer']).to be false
    end
  end

  context 'when a boolean option is "f"' do
    let(:options) { { 'display_header_footer' => 'f' } }

    it 'converts the option to a false literal' do
      expect(fixed_options['display_header_footer']).to be false
    end
  end

  context 'when a boolean option is "F"' do
    let(:options) { { 'display_header_footer' => 'F' } }

    it 'converts the option to a false literal' do
      expect(fixed_options['display_header_footer']).to be false
    end
  end

  context 'when a boolean option is "off"' do
    let(:options) { { 'display_header_footer' => 'off' } }

    it 'converts the option to a false literal' do
      expect(fixed_options['display_header_footer']).to be false
    end
  end

  context 'when a boolean option is "OFF"' do
    let(:options) { { 'display_header_footer' => 'OFF' } }

    it 'converts the option to a false literal' do
      expect(fixed_options['display_header_footer']).to be false
    end
  end

  context 'when a boolean option is "0"' do
    let(:options) { { 'display_header_footer' => '0' } }

    it 'converts the option to a false literal' do
      expect(fixed_options['display_header_footer']).to be false
    end
  end

  context 'when a boolean option is 0' do
    let(:options) { { 'display_header_footer' => 0 } }

    it 'converts the option to a false literal' do
      expect(fixed_options['display_header_footer']).to be false
    end
  end

  context 'when a boolean option is false' do
    let(:options) { { 'display_header_footer' => false } }

    it 'converts the option to a false literal' do
      expect(fixed_options['display_header_footer']).to be false
    end
  end

  context 'when a boolean option is truthy' do
    let(:options) { { 'display_header_footer' => 'true' } }

    it 'converts the options to a false literal' do
      expect(fixed_options['display_header_footer']).to be true
    end
  end

  context 'with an integer option' do
    let(:options) { { 'viewport' => { 'width' => '123' } } }

    it 'converts the option to a float' do
      expect(fixed_options['viewport']['width']).to eq 123
    end
  end

  context 'with a float option' do
    let(:options) { { 'viewport' => { 'device_scale_factor' => '123.456' } } }

    it 'converts the option to an integer' do
      expect(fixed_options['viewport']['device_scale_factor']).to eq 123.456
    end
  end

  context 'with an array option' do
    let(:options) { { 'launch_args' => "['--some-option']" } }

    it 'converts the option to an array' do
      expect(fixed_options['launch_args']).to eq ['--some-option']
    end
  end
end
