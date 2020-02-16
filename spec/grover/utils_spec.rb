# frozen_string_literal: true

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

  describe '.deep_assign' do
    subject(:deep_assign) { described_class.deep_assign(hash, keys, value) }

    let(:value) { 'baz' }

    context 'when hash is empty' do
      let(:hash) { {} }
      let(:keys) { ['foo'] }

      it do
        deep_assign
        expect(hash).to eq('foo' => 'baz')
      end
    end

    context 'when hash already contains matching key' do
      let(:hash) { { 'foo' => 'bar' } }
      let(:keys) { ['foo'] }

      it do
        deep_assign
        expect(hash).to eq('foo' => 'baz')
      end
    end

    context 'with multiple keys provided' do
      let(:hash) { {} }
      let(:keys) { %w[foo bar] }

      it do
        deep_assign
        expect(hash).to eq('foo' => { 'bar' => 'baz' })
      end
    end

    context 'with symbol keys' do
      let(:hash) { {} }
      let(:keys) { %i[foo bar] }

      it do
        deep_assign
        expect(hash).to eq(foo: { bar: 'baz' })
      end
    end
  end

  describe '.deep_transform_keys_in_object' do
    subject(:deep_transform_keys_in_object) do
      described_class.deep_transform_keys_in_object(hash) { |key| key.to_s.upcase }
    end

    context 'when hash is empty' do
      let(:hash) { {} }

      it { is_expected.to eq({}) }
    end

    context 'when hash has basic keys' do
      let(:hash) { { foo: 'bar' } }

      it { is_expected.to eq('FOO' => 'bar') }

      it 'doesnt modify the original hash' do
        deep_transform_keys_in_object
        expect(hash).to eq(foo: 'bar')
      end
    end

    context 'when hash contains an array of hashes' do
      let(:hash) { { foo: [{ bar: 'baz' }] } }

      it { is_expected.to eq('FOO' => [{ 'BAR' => 'baz' }]) }

      it 'doesnt modify the original hash' do
        deep_transform_keys_in_object
        expect(hash).to eq(foo: [{ bar: 'baz' }])
      end
    end
  end

  describe '.deep_stringify_keys' do
    subject(:deep_stringify_keys) { described_class.deep_stringify_keys(hash) }

    context 'when hash is empty' do
      let(:hash) { {} }

      it { is_expected.to eq({}) }
    end

    context 'when hash has keys' do
      let(:hash) { { foo: 'bar' } }

      it { is_expected.to eq('foo' => 'bar') }

      it 'doesnt modify the original hash' do
        deep_stringify_keys
        expect(hash).to eq(foo: 'bar')
      end
    end
  end

  describe '.deep_merge!' do
    subject(:deep_merge!) { described_class.deep_merge! hash1, hash2 }

    context 'when both hashes are empty' do
      let(:hash1) { {} }
      let(:hash2) { {} }

      it { is_expected.to eq({}) }

      it 'leaves the first hash empty' do
        deep_merge!
        expect(hash1).to eq({})
      end

      it 'leaves the second hash empty' do
        deep_merge!
        expect(hash2).to eq({})
      end
    end

    context 'when hash1 has some keys' do
      let(:hash1) { { foo: 'bar' } }
      let(:hash2) { {} }

      it { is_expected.to eq(foo: 'bar') }

      it 'leaves the first hash as it was' do
        deep_merge!
        expect(hash1).to eq(foo: 'bar')
      end

      it 'leaves the second hash empty' do
        deep_merge!
        expect(hash2).to eq({})
      end
    end

    context 'when hash2 has some keys' do
      let(:hash1) { {} }
      let(:hash2) { { foo: 'bar' } }

      it { is_expected.to eq(foo: 'bar') }

      it 'updates hash1 to include the contents from hash2' do
        deep_merge!
        expect(hash1).to eq(foo: 'bar')
      end

      it 'leaves the second hash as it was' do
        deep_merge!
        expect(hash2).to eq(foo: 'bar')
      end
    end

    context 'when both hashes have keys (different)' do
      let(:hash1) { { bar: 'baz' } }
      let(:hash2) { { foo: 'bar' } }

      it { is_expected.to eq(foo: 'bar', bar: 'baz') }

      it 'merges the contents of hash1 and hash2' do
        deep_merge!
        expect(hash1).to eq(foo: 'bar', bar: 'baz')
      end

      it 'leaves the second hash as it was' do
        deep_merge!
        expect(hash2).to eq(foo: 'bar')
      end
    end

    context 'when both hashes have keys (same)' do
      let(:hash1) { { foo: 'baz', baz: 'foo' } }
      let(:hash2) { { foo: 'bar' } }

      it { is_expected.to eq(foo: 'bar', baz: 'foo') }

      it 'overloads existing key values in hash1' do
        deep_merge!
        expect(hash1).to eq(foo: 'bar', baz: 'foo')
      end

      it 'leaves the second hash as it was' do
        deep_merge!
        expect(hash2).to eq(foo: 'bar')
      end
    end

    context 'when both hashes have keys (same/deep)' do
      let(:hash1) { { foo: { bar: 'baz' }, fizz: 'buzz' } }
      let(:hash2) { { foo: { baz: 'bar', bar: 'foo' } } }

      it { is_expected.to eq(foo: { bar: 'foo', baz: 'bar' }, fizz: 'buzz') }

      it 'overloads existing deep key values in hash1' do
        deep_merge!
        expect(hash1).to eq(foo: { bar: 'foo', baz: 'bar' }, fizz: 'buzz')
      end

      it 'leaves the second hash as it was' do
        deep_merge!
        expect(hash2).to eq(foo: { baz: 'bar', bar: 'foo' })
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
