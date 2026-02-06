# frozen_string_literal: true

class Grover
  #
  # DevToolsParser helper class for simplifying the debug output
  #
  class DevToolsParser
    class << self
      def parse(raw_devtools_output) # rubocop:disable Metrics/MethodLength
        lines = raw_devtools_output.strip.split("\n")
        simplified_output = []

        while lines.any?
          if starts_with_array_pattern? lines
            simplified_output.push extract_array_pattern!(lines)
          elsif starts_with_hash_pattern? lines
            simplified_output.push extract_hash_pattern!(lines)
          else
            simplified_output.push lines.shift
          end
        end

        simplified_output
      end

      private

      def starts_with_array_pattern?(lines)
        lines.length >= 3 && lines[0].end_with?(' [') && lines[1].start_with?("  '") && lines[2] == ']'
      end

      def extract_array_pattern!(lines)
        "#{lines.shift}#{lines.shift[1..]} #{lines.shift}"
      end

      def starts_with_hash_pattern?(lines)
        return false unless lines.length >= 3 && lines[0].end_with?(' {')

        last_hash_line = lines[1..].index { |line| !line.match?(/\A  .*,\z/) }
        return false if last_hash_line.nil?

        lines[last_hash_line + 1].match?(/\A  .*[^,]\z/) && lines[last_hash_line + 2] == '}'
      end

      def extract_hash_pattern!(lines)
        result = lines.shift
        result += lines.shift[1..] while lines[0] != '}'
        result + " #{lines.shift}"
      end
    end
  end
end
