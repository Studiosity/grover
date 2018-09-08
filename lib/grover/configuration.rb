class Grover
  #
  # Configuration of the options for Grover HTML to PDF conversion
  #
  class Configuration
    attr_accessor :options, :meta_tag_prefix

    def initialize
      @options = {}
      @meta_tag_prefix = 'grover-'
    end
  end
end
