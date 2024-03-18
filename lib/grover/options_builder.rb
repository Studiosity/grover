# frozen_string_literal: true

require 'grover/utils'
require 'grover/options_fixer'

class Grover
  #
  # Build options from Grover.configuration, meta_options, and passed-in options
  #
  class OptionsBuilder < Hash
    def initialize(options, url, middleware:)
      super()
      @url = url
      combined = grover_configuration
      Utils.deep_merge! combined, Utils.deep_stringify_keys(options)
      Utils.deep_merge! combined, meta_options unless url_source?

      update OptionsFixer.new(combined).run

      # The combination of middleware and allowing file URLs is exceptionally
      # unsafe as it can lead to data exfiltration from the host system.
      return unless middleware && (self['allow_file_url'] || self['allowFileUrl'])

      raise UnsafeConfigurationError, 'using `allow_file_url` option with middleware is exceptionally unsafe'
    end

    private

    def grover_configuration
      Utils.deep_stringify_keys Grover.configuration.options
    end

    #
    # Extract out options from meta tags in the source - based on code from PDFKit project
    #
    def meta_options
      meta_opts = {}

      meta_tags.each do |meta|
        tag_name = meta['name'] && meta['name'][/#{Grover.configuration.meta_tag_prefix}([a-z_-]+)/, 1]
        next unless tag_name

        Utils.deep_assign meta_opts, tag_name.split('-'), meta['content']
      end

      meta_opts
    end

    def meta_tags
      Nokogiri::HTML(@url).xpath('//meta')
    end

    def url_source?
      @url.match(/\A(http|file)/i)
    end
  end
end
