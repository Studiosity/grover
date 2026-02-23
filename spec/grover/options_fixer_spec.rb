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

    it 'converts the option to a true literal' do
      expect(fixed_options['display_header_footer']).to be true
    end
  end

  context 'with an integer option' do
    let(:options) { { 'viewport' => { 'width' => '123' } } }

    it 'converts the option to an integer' do
      expect(fixed_options['viewport']['width']).to eq 123
    end
  end

  context 'with a float option' do
    let(:options) { { 'viewport' => { 'device_scale_factor' => '123.456' } } }

    it 'converts the option to a float' do
      expect(fixed_options['viewport']['device_scale_factor']).to eq 123.456
    end
  end

  context 'with an array option' do
    let(:options) { { 'launch_args' => "['--some-option']" } }

    it 'converts the option to an array' do
      expect(fixed_options['launch_args']).to eq ['--some-option']
    end
  end

  context 'when javascript_enabled option is set' do
    let(:options) do
      {
        'javascript_enabled' => enabled,
        'evaluate_on_new_document' => 'test 1',
        'execute_script' => 'test 2',
        'script_tag_options' => 'test 3',
        'wait_for_function' => 'test 4'
      }
    end

    context 'when it is true' do
      let(:enabled) { 'true' }

      it 'keep javascript options' do
        expect(fixed_options['javascript_enabled']).to be true
        expect(fixed_options['evaluate_on_new_document']).to eq 'test 1'
        expect(fixed_options['execute_script']).to eq 'test 2'
        expect(fixed_options['script_tag_options']).to eq 'test 3'
        expect(fixed_options['wait_for_function']).to eq 'test 4'
      end
    end

    context 'when it is false' do
      let(:enabled) { 'false' }

      it 'disable javascript options' do
        expect(fixed_options['javascript_enabled']).to be false
        expect(fixed_options['evaluate_on_new_document']).to be_nil
        expect(fixed_options['execute_script']).to be_nil
        expect(fixed_options['script_tag_options']).to be_nil
        expect(fixed_options['wait_for_function']).to be_nil
      end
    end
  end
end
