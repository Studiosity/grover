require 'spec_helper'

describe Grover do
  describe '.new' do
    subject(:new) { Grover.new('http://google.com') }

    it { is_expected.to be_a Grover }
    it { expect(subject.instance_variable_get('@url')).to eq 'http://google.com' }
    it { expect(subject.instance_variable_get('@options')).to eq({}) }

    context 'with options passed' do
      subject(:new) { Grover.new('http://happyfuntimes.com', page_size: 'A4') }

      it { expect(subject.instance_variable_get('@url')).to eq 'http://happyfuntimes.com' }
      it { expect(subject.instance_variable_get('@options')).to eq(page_size: 'A4') }
    end
  end

  describe '#to_pdf' do
    subject(:to_pdf) { Grover.new('https://www.google.com').to_pdf }

    it { is_expected.to start_with "%PDF-1.4\n" }
  end
end
