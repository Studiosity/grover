class Grover
  #
  # Utility class for Grover helper methods
  #
  class Utils
    def self.squish(string)
      string.
        gsub(/\A[[:space:]]+/, '').
        gsub(/[[:space:]]+\z/, '').
        gsub(/[[:space:]]+/, ' ')
    end
  end
end
