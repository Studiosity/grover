# frozen_string_literal: true

class Grover
  #
  # Error classes for calling out to Puppeteer NodeJS library
  #
  # Heavily based on the Schmooze library https://github.com/Shopify/schmooze
  #
  Error = Class.new(StandardError)
  DependencyError = Class.new(Error)
  module JavaScript # rubocop:disable Style/Documentation
    Error = Class.new(::Grover::Error)
    UnknownError = Class.new(Error)

    ErrorWithDetails = Class.new(Error) do
      def initialize(name, error_details)
        super(name)
        @error_details = Grover::Utils.deep_transform_keys_in_object error_details, &:to_sym
      end

      attr_reader :error_details
    end
    RequestFailedError = Class.new(ErrorWithDetails)
    PageRenderError = Class.new(ErrorWithDetails)

    def self.const_missing(name)
      const_set name, Class.new(Error)
    end
  end
  UnsafeConfigurationError = Class.new(Error)
end
