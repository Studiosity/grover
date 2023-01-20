# frozen_string_literal: true

require 'spec_helper'

describe 'DeepDup' do
  describe 'Object' do
    it 'deep duplicates objects' do
      object = Object.new
      dup = object.deep_dup
      dup.instance_variable_set(:@a, 1)
      expect(object.instance_variable_defined?(:@a)).to be false
      expect(dup.instance_variable_defined?(:@a)).to be true
    end
  end

  describe 'Array' do
    it 'deep duplicates arrays' do
      array = [1, [2, 3]]
      dup = array.deep_dup
      dup[1][2] = 4
      expect(array[1][2]).to be_nil
      expect(dup[1][2]).to eq 4
    end

    it 'deep duplicates arrays with hash inside' do
      array = [1, { a: 2, b: 3 }]
      dup = array.deep_dup
      dup[1][:c] = 4
      expect(array[1][:c]).to be_nil
      expect(dup[1][:c]).to eq 4
    end
  end

  describe 'Hash' do
    it 'deep duplicates hashes' do
      hash = { a: { b: 'b' } }
      dup = hash.deep_dup
      dup[:a][:c] = 'c'
      expect(hash[:a][:c]).to be_nil
      expect(dup[:a][:c]).to eq 'c'
    end

    it 'deep duplicates hashes with arrays inside' do
      hash = { a: [1, 2] }
      dup = hash.deep_dup
      dup[:a][2] = 'c'
      expect(hash[:a][2]).to be_nil
      expect(dup[:a][2]).to eq 'c'
    end

    it 'deep duplicates hash initialisation' do
      zero_hash = Hash.new 0
      hash = { a: zero_hash }
      dup = hash.deep_dup
      expect(dup[:a][44]).to eq 0
    end

    it 'deep duplicates hashes with string key' do
      hash = { 'a' => { b: 'b' } }
      dup = hash.deep_dup
      dup['a'][:c] = 'c'
      expect(hash['a'][:c]).to be_nil
      expect(dup['a'][:c]).to eq 'c'
    end

    it 'deep duplicates hash with class key' do
      hash = { Integer => 1 }
      dup = hash.deep_dup
      expect(dup.keys.length).to eq 1
    end
  end
end
