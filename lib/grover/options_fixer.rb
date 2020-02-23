require 'grover/utils'

class Grover

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

    def fix_options!(*options)
      options.each do |option|
        keys = option.split '.'
        value = @options.dig(*keys)
        Utils.deep_assign(@options, keys, yield(value)) if value
      end
    end

    def fix_boolean_options!
      fix_options!('display_header_footer', 'print_background', 'landscape', 'prefer_css_page_size') do |value|
        !FALSE_VALUES.include? value
      end
    end

    def string_to_bool(value)
      !FALSE_VALUES.include?(value)
    end

    def fix_integer_options!
      fix_options!('viewport.width', 'viewport.height') do |value|
        value.to_i
      end
    end

    def fix_float_options!
      fix_options!('viewport.device_scale_factor', 'scale') do |value|
        value.to_f
      end
    end

    def fix_array_options!
      fix_options!('launch_args') do |value|
        value.is_a?(String) ? YAML.safe_load(value) : value
      end
    end
  end
end
