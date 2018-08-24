require 'spec_helper'

describe Grover::Utils do
  describe '.squish' do
    subject(:squish) { described_class.squish string }

    context 'with an empty string' do
      let(:string) { '' }

      it { is_expected.to eq '' }
    end

    context 'with leading spaces' do
      let(:string) { '   Foo' }

      it { is_expected.to eq 'Foo' }
    end

    context 'with trailing spaces' do
      let(:string) { 'Bar   ' }

      it { is_expected.to eq 'Bar' }
    end

    context 'with spaces in the middle' do
      let(:string) { 'Foo Bar    Baz' }

      it { is_expected.to eq 'Foo Bar Baz' }
    end

    context 'with newlines' do
      let(:string) { "\nFoo\nBar Baz\nBoop\n" }

      it { is_expected.to eq 'Foo Bar Baz Boop' }
    end

    context 'with tabs' do
      let(:string) { "Foo\tBar" }

      it { is_expected.to eq 'Foo Bar' }
    end
  end

  describe '.strip_heredoc' do
    subject(:strip_heredoc) { described_class.strip_heredoc string }

    context 'with an empty string' do
      let(:string) { '' }

      it { is_expected.to eq '' }
    end

    context 'with a multi-line string and no padding' do
      let(:string) { "Hey there\nbuddy\n" }

      it { is_expected.to eq string }
    end

    context 'with a multi-line string and equal space padding' do
      let(:string) { "    Hey there\n    buddy\n" }

      it { is_expected.to eq "Hey there\nbuddy\n" }
    end

    context 'with a multi-line string where first line has shorter space padding' do
      let(:string) { "  Hey there\n   buddy" }

      it { is_expected.to eq "Hey there\n buddy" }
    end

    context 'with a multi-line string where second line has shorter space padding' do
      let(:string) { "  Hey there\n buddy" }

      it { is_expected.to eq " Hey there\nbuddy" }
    end

    context 'when the optional `inline` flag is set to true' do
      subject(:strip_heredoc) { described_class.strip_heredoc string, inline: true }

      context 'with a multi-line string' do
        let(:string) { "  Hey there\n   buddy\n" }

        it { is_expected.to eq 'Hey there buddy' }
      end
    end
  end

  describe '.normalize_object' do
    subject(:normalize_object) { described_class.normalize_object(object) }

    context 'when key is a single-word symbol' do
      let(:object) { { foo: 'bar' } }

      it { is_expected.to eq('foo' => 'bar') }
    end

    context 'when key is a multi-word symbol' do
      let(:object) { { foo_bar: 'baz' } }

      it { is_expected.to eq('fooBar' => 'baz') }
    end

    context 'when key is a single-word string' do
      let(:object) { { 'foo' => 'bar' } }

      it { is_expected.to eq('foo' => 'bar') }
    end

    context 'when key is a multi-word string' do
      let(:object) { { 'foo_bar' => 'baz' } }

      it { is_expected.to eq('fooBar' => 'baz') }
    end

    context 'when key is up-case' do
      let(:object) { { 'FOO_BAR' => 'baz' } }

      it { is_expected.to eq('fooBar' => 'baz') }
    end

    context 'when key has an acronym in it' do
      let(:object) { { prefer_css_page_size: true } }

      it { is_expected.to eq('preferCSSPageSize' => true) }
    end

    context 'with nested Hashes' do
      let(:object) { { margin: { top: '5px' } } }

      it { is_expected.to eq('margin' => { 'top' => '5px' }) }
    end

    context 'when value is a number' do
      let(:object) { { scale: 1.34 } }

      it { is_expected.to eq('scale' => 1.34) }
    end
  end
end
