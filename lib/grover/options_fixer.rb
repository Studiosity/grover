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

    def fix_boolean_options!
      %w[display_header_footer print_background landscape prefer_css_page_size].each do |opt|
        keys = opt.split('.')
        Utils.deep_assign(@options, keys, string_to_bool(@options.dig(*keys))) if @options.dig(*keys)
      end
    end

    def string_to_bool(value)
      !FALSE_VALUES.include?(value)
    end

    def fix_integer_options!
      ['viewport.width', 'viewport.height'].each do |opt|
        keys = opt.split('.')
        Utils.deep_assign(@options, keys, @options.dig(*keys).to_i) if @options.dig(*keys)
      end
    end

    def fix_float_options!
      ['viewport.device_scale_factor', 'scale'].each do |opt|
        keys = opt.split('.')
        Utils.deep_assign(@options, keys, @options.dig(*keys).to_f) if @options.dig(*keys)
      end
    end

    def fix_array_options!
      %w[launch_args].each do |opt|
        keys = opt.split('.')
        Utils.deep_assign(@options, keys, YAML.safe_load(@options.dig(*keys))) if @options.dig(*keys)
      end
    end
  end
end