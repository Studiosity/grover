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
    # Recursively normalizes hash objects with camelized string keys
    #
    def self.normalize_object(object)
      if object.is_a? Hash
        object.each_with_object({}) do |(k, v), acc|
          acc[normalize_key(k)] = normalize_object(v)
        end
      else
        object
      end
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
