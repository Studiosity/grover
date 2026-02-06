# frozen_string_literal: true

class Grover
  #
  # Error classes for calling out to Puppeteer NodeJS library
  #
  # Heavily based on the Schmooze library https://github.com/Shopify/schmooze
  #
  class Error < StandardError
  end

  class DependencyError < Error
  end

  module JavaScript # rubocop:disable Style/Documentation
    class Error < ::Grover::Error
    end

    class UnknownError < Error
    end

    ErrorWithDetails = Class.new(Error) do
      def initialize(name, error_details)
        super(name)
        @error_details = Grover::Utils.deep_transform_keys_in_object error_details, &:to_sym
      end

      attr_reader :error_details
    end
    class RequestFailedError < ErrorWithDetails
    end

    class PageRenderError < ErrorWithDetails
    end

    def self.const_missing(name)
      const_set name, Class.new(Error)
    end
  end

  class UnsafeConfigurationError < Error
  end
end
