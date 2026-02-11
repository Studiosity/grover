# frozen_string_literal: true

require 'grover/utils'

class Grover
  #
  # Convert string option values to boolean, numeric, and array literals
  #
  class OptionsFixer
    FALSE_VALUES = [nil, false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].freeze

    def initialize(options)
      @options = options
    end

    def run
      fix_boolean_options!
      fix_integer_options!
      fix_float_options!
      fix_array_options!
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
        'raise_on_request_failure', 'raise_on_js_error'
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
  end
end
