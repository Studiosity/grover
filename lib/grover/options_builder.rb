# frozen_string_literal: true

require 'grover/utils'
require 'grover/options_fixer'

class Grover
  #
  # Build options from Grover.configuration, meta_options, and passed-in options
  #
  class OptionsBuilder < Hash
    #
    # Presentation-only options that are safe to accept from untrusted HTML meta tags.
    # Anything not listed here (e.g. executable_path, launch_args, browser_ws_endpoint,
    # path, root_path, front/back_cover_path, display_url, cookies, credentials) is
    # ignored when it comes from a meta tag, to prevent option injection from page content.
    #
    META_OPTION_ALLOWLIST = %w[
      capture_beyond_viewport clip display_header_footer emulate_media focus footer_template format full_page
      geolocation header_template height hover landscape margin media_features omit_background outline page_ranges
      prefer_css_page_size print_background quality scale tagged timezone viewport vision_deficiency width
    ].freeze
    private_constant :META_OPTION_ALLOWLIST
    META_OPTION_RESTRICTED_LIST = %w[front_cover_path back_cover_path].freeze
    private_constant :META_OPTION_RESTRICTED_LIST

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
        keys = allowed_meta_keys meta['name'], meta['content']
        Utils.deep_assign meta_opts, keys, meta['content'] if keys
      end
      meta_opts
    end

    def allowed_meta_keys(name, value)
      # Check that the meta tag actually has a name
      return unless name

      # Extract out the meta tag name, removing the "prefix" (default `grover-`) eg `grover-format` => `format`
      tag_name = name[/\A#{Regexp.escape(Grover.configuration.meta_tag_prefix)}([a-z_-]{1,100})\z/, 1]
      return if tag_name.nil? # No match
      return if /\A[_-]/.match?(tag_name) || /[_-]\z/.match?(tag_name) # Starts or ends with _/- (invalid)

      # Split the tag by `-` to allow support for nested meta attributes e.g. `grover-margin-top` => `['margin', 'top']`
      keys = tag_name.split('-')

      # Only return the keys if they're allowed (either explicitly from the allow list, or if the configuration
      # allows restricted options. Disallows any "control" options)
      keys if allow_meta_key? tag_name, keys.first, value
    end

    def allow_meta_key?(tag_name, primary_key, value) # rubocop:disable Metrics/MethodLength
      # Allow any meta tags where the primary part of the key matches the allow list
      return true if META_OPTION_ALLOWLIST.include? primary_key

      # Deny any meta tags that don't match exactly to the restricted list
      return false unless META_OPTION_RESTRICTED_LIST.include? tag_name

      # Check the `allow_restricted_meta_option` configuration whether the restricted meta option is allowed
      case Grover.configuration.allow_restricted_meta_option
      when Proc then Grover.configuration.allow_restricted_meta_option.call tag_name, value
      when true, false then Grover.configuration.allow_restricted_meta_option
      else
        raise UnsafeConfigurationError, Utils.squish(<<~ERROR)
          Grover.configuration.allow_restricted_meta_option must be true, false
          or a Proc that takes the meta tag name and value and returns true or false
        ERROR
      end
    end

    def meta_tags
      Nokogiri::HTML(@uri).xpath('//meta')
    end

    def uri_source?
      @uri.match?(%r{\A(https?|file)://}i)
    end
  end
end
