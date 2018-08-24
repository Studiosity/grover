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
end
