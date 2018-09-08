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
    subject(meta_tag_prefix) { configuration.meta_tag_prefix }

    it { is_expected.to eq 'grover-' }

    context 'when configured differently' do
      before { configuration.meta_tag_prefix = 'fooPrefix-' }

      it { is_expected.to eq 'fooPrefix-' }
    end
  end
end
