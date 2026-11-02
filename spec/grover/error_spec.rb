# frozen_string_literal: true

require 'spec_helper'

describe Grover::Error do
  it { is_expected.to be_a StandardError }

  describe 'Grover::DependencyError' do
    subject { Grover::DependencyError.new }

    it { is_expected.to be_a described_class }
  end

  describe 'Grover::JavaScript::Error' do
    subject { Grover::JavaScript::Error.new }

    it { is_expected.to be_a described_class }
  end

  describe 'Grover::JavaScript::UnknownError' do
    subject { Grover::JavaScript::UnknownError.new }

    it { is_expected.to be_a Grover::JavaScript::Error }
  end

  describe 'Grover::JavaScript::SomeOtherError' do
    subject { Grover::JavaScript::SomeOtherError.new }

    it { is_expected.to be_a Grover::JavaScript::Error }
  end
end
