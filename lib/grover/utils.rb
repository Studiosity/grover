class Grover
  #
  # Utility class for Grover helper methods
  #
  class Utils
    ACRONYMS = {
      'css' => 'CSS'
    }.freeze
    private_constant :ACRONYMS

    #
    # Removes leading/trailing whitespaces and squishes inner whitespace with a single space
    #
    # N.B. whitespace includes all 'blank' characters as well as newlines/carriage returns etc.
    #
    def self.squish(string)
      string.
        gsub(/\A[[:space:]]+/, '').
        gsub(/[[:space:]]+\z/, '').
        gsub(/[[:space:]]+/, ' ')
    end

    #
    # Remove minimum spaces from the front of all lines within a string
    #
    # Based on active support
    # @see active_support/core_ext/string/strip.rb
    #
    def self.strip_heredoc(string, inline: false)
      string = string.gsub(/^#{string.scan(/^[ \t]*(?=\S)/).min}/, ''.freeze)
      inline ? string.delete("\n") : string
    end

    #
    # Assign value to a hash using an array of keys to traverse
    #
    def self.deep_assign(hash, keys, value)
      if keys.length == 1
        hash[keys.first] = value
      else
        key = keys.shift
        hash[key] ||= {}
        deep_assign hash[key], keys, value
      end
    end

    #
    # Deep transform the keys in an object (Hash/Array)
    #
    # Copied from active support
    # @see active_support/core_ext/hash/keys.rb
    #
    def self.deep_transform_keys_in_object(object, &block)
      case object
      when Hash
        object.each_with_object({}) do |(key, value), result|
          result[yield(key)] = deep_transform_keys_in_object(value, &block)
        end
      when Array
        object.map { |e| deep_transform_keys_in_object(e, &block) }
      else
        object
      end
    end

    def self.deep_stringify_keys(hash)
      deep_transform_keys_in_object hash, &:to_s
    end

    #
    # Deep merge a hash with another hash
    #
    # Copied from active support
    # @see active_support/core_ext/hash/deep_merge.rb
    #
    def self.deep_merge!(hash, other_hash, &block)
      hash.merge!(other_hash) do |key, this_val, other_val|
        if this_val.is_a?(Hash) && other_val.is_a?(Hash)
          deep_merge!(this_val.dup, other_val, &block)
        elsif block_given?
          block.call(key, this_val, other_val)
        else
          other_val
        end
      end
    end

    #
    # Recursively normalizes hash objects with camelized string keys
    #
    def self.normalize_object(object)
      deep_transform_keys_in_object(object) { |k| normalize_key(k) }
    end

    #
    # Normalizes hash keys into camelized strings, including up-casing known acronyms
    #
    # Regex sourced from ActiveSupport camelize
    #
    def self.normalize_key(key)
      key.to_s.downcase.gsub(%r{(?:_|(/))([a-z\d]*)}) do
        "#{Regexp.last_match(1)}#{ACRONYMS[Regexp.last_match(2)] || Regexp.last_match(2).capitalize}"
      end
    end
    private_class_method :normalize_key
  end
end
