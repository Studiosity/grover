# frozen_string_literal: true

require 'grover/utils'

class Grover
  #
  # Convert string option values to boolean, numeric, and array literals
  #
  class OptionsFixer
    FALSE_VALUES = [nil, false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].freeze

    JAVASCRIPT_OPTIONS = %w[evaluate_on_new_document execute_script script_tag_options wait_for_function].freeze
    private_constant :JAVASCRIPT_OPTIONS

    def initialize(options)
      @options = options
    end

    def run
      fix_boolean_options!
      fix_integer_options!
      fix_float_options!
      fix_array_options!
      disable_javascript_options!
      @options
    end

    private

    def fix_options!(*option_paths)
      option_paths.each do |option_path|
        keys = option_path.split '.'
        value = @options.dig(*keys)
        Utils.deep_assign(@options, keys, yield(value)) if value
      end
    end

    def fix_boolean_options!
      fix_options!(
        'display_header_footer', 'full_page', 'landscape', 'omit_background', 'prefer_css_page_size',
        'print_background', 'viewport.has_touch', 'viewport.is_landscape', 'viewport.is_mobile', 'bypass_csp',
        'raise_on_request_failure', 'raise_on_js_error', 'javascript_enabled'
      ) { |value| !FALSE_VALUES.include?(value) }
    end

    def fix_integer_options!
      fix_options!(
        'viewport.height', 'viewport.width',
        'timeout', 'launch_timeout', 'request_timeout', 'convert_timeout', 'wait_for_timeout',
        &:to_i
      )
    end

    def fix_float_options!
      fix_options!(
        'clip.height', 'clip.width', 'clip.x', 'clip.y', 'quality', 'scale', 'viewport.device_scale_factor',
        'geolocation.latitude', 'geolocation.longitude',
        &:to_f
      )
    end

    def fix_array_options!
      fix_options!('launch_args') do |value|
        value.is_a?(String) ? YAML.safe_load(value) : value
      end
    end

    def disable_javascript_options!
      return if @options['javascript_enabled'] != false

      JAVASCRIPT_OPTIONS.each do |option|
        disable_javascript_option!(option)
      end
    end

    def disable_javascript_option!(option)
      return unless @options.key?(option)

      @options.delete(option)
      warn "#{self.class}: option #{option} has been disabled because javascript_enabled is set to false"
    end
  end
end
