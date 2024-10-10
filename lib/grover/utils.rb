# frozen_string_literal: true

class Grover
  #
  # Utility class for Grover helper methods
  #
  class Utils
    ACRONYMS = {
      'css' => 'CSS',
      'csp' => 'CSP',
      'http' => 'HTTP',
      'js' => 'JS'
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
    def self.deep_transform_keys_in_object(object, excluding: [], &block) # rubocop:disable Metrics/MethodLength
      case object
      when Hash
        object.each_with_object({}) do |(key, value), result|
          new_key = yield(key)
          result[new_key] = excluding.include?(new_key) ? value : deep_transform_keys_in_object(value, &block)
        end
      when Array
        object.map { |e| deep_transform_keys_in_object(e, &block) }
      else
        object
      end
    end

    #
    # Deep transform the keys in the hash to strings
    #
    def self.deep_stringify_keys(hash)
      deep_transform_keys_in_object hash, &:to_s
    end

    #
    # Deep merge a hash with another hash
    #
    # Based on active support
    # @see active_support/core_ext/hash/deep_merge.rb
    #
    def self.deep_merge!(hash, other_hash)
      hash.merge!(other_hash) do |_, this_val, other_val|
        if this_val.is_a?(Hash) && other_val.is_a?(Hash)
          deep_merge! this_val.dup, other_val
        else
          other_val
        end
      end
    end

    #
    # Recursively normalizes hash objects with camelized string keys
    #
    def self.normalize_object(object, excluding: [])
      deep_transform_keys_in_object(object, excluding: excluding) { |k| normalize_key(k) }
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
