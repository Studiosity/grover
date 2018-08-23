require 'spec_helper'

describe Grover do
  describe '.new' do
    subject(:new) { Grover.new('http://google.com') }

    it { is_expected.to be_a Grover }
    it { expect(subject.instance_variable_get('@url')).to eq 'http://google.com' }
    it { expect(subject.instance_variable_get('@root_path')).to be_nil }
    it { expect(subject.instance_variable_get('@options')).to eq({}) }

    context 'with options passed' do
      subject(:new) { Grover.new('http://happyfuntimes.com', options) }

      let(:options) { { page_size: 'A4' } }

      it { expect(subject.instance_variable_get('@url')).to eq 'http://happyfuntimes.com' }
      it { expect(subject.instance_variable_get('@root_path')).to be_nil }
      it { expect(subject.instance_variable_get('@options')).to eq(page_size: 'A4') }

      context 'root path specified' do
        let(:options) { { page_size: 'A4', root_path: 'foo/bar/baz' } }

        it { expect(subject.instance_variable_get('@url')).to eq 'http://happyfuntimes.com' }
        it { expect(subject.instance_variable_get('@root_path')).to eq 'foo/bar/baz' }
        it { expect(subject.instance_variable_get('@options')).to eq(page_size: 'A4') }
      end
    end
  end

  describe '#to_pdf' do
    subject(:to_pdf) { Grover.new(url_or_html).to_pdf }

    context 'when passing through a valid URL' do
      let(:url_or_html) { 'https://www.google.com' }

      it { is_expected.to start_with "%PDF-1.4\n" }
    end

    context 'when passing through an invalid URL' do
      let(:url_or_html) { 'https://fake.invalid' }

      it do
        expect do
          subject
        end.to raise_error Schmooze::JavaScript::Error, %r{net::ERR_NAME_NOT_RESOLVED at https://fake.invalid}
      end
    end

    context 'when passing through html' do
      let(:url_or_html) { '<html><body><h1>Hey there</h1></body></html>' }

      it { is_expected.to start_with "%PDF-1.4\n" }
    end
  end

  describe '#inspect' do
    subject(:inspect) { grover.inspect }

    let(:grover) { Grover.new('http://google.com') }

    it { is_expected.to eq "#<Grover:0x#{grover.object_id} @url=\"http://google.com\">" }
  end
end
