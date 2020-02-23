require 'grover/utils'
require 'grover/options_fixer'

class Grover

  class OptionsBuilder < Hash

    def initialize(options, url)
      @url = url
      options = Utils.deep_stringify_keys(options)
      Utils.deep_merge!(options, grover_configuration)
      Utils.deep_merge!(options, meta_options) unless url_source?
      self.merge!(OptionsFixer.new(options).run)
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