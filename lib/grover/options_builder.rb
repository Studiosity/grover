# frozen_string_literal: true

require 'grover/utils'
require 'grover/options_fixer'

class Grover
  #
  # Build options from Grover.configuration, meta_options, and passed-in options
  #
  class OptionsBuilder < Hash
    def initialize(options, uri)
      super()
      @uri = uri
      combined = grover_configuration
      Utils.deep_merge! combined, Utils.deep_stringify_keys(options)
      Utils.deep_merge! combined, meta_options unless uri_source?

      update OptionsFixer.new(combined).run
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
      Nokogiri::HTML(@uri).xpath('//meta')
    end

    def uri_source?
      @uri.match?(%r{\A(https?|file)://}i)
    end
  end
end
