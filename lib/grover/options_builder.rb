# frozen_string_literal: true

require 'grover/utils'
require 'grover/options_fixer'

class Grover
  #
  # Build options from Grover.configuration, meta_options, and passed-in options
  #
  class OptionsBuilder < Hash
    def initialize(options, url)
      @url = url
      combined = grover_configuration
      Utils.deep_merge! combined, Utils.deep_stringify_keys(options)
      Utils.deep_merge! combined, meta_options unless url_source?
      update(OptionsFixer.new(combined).run)
    end

    private

    def grover_configuration
      Utils.deep_stringify_keys Grover.configuration.options
    end

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
      @url.match(/\Ahttp/i)
    end
  end
end
