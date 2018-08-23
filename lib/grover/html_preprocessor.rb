class Grover
  #
  # Helper module for preparing HTML for conversion
  #
  # Sourced from the PDFKit project
  # @see https://github.com/pdfkit/pdfkit
  #
  module HTMLPreprocessor
    # Change relative paths to absolute, and relative protocols to absolute protocols
    def self.process(html, root_url, protocol)
      html = translate_relative_paths(html, root_url) if root_url
      html = translate_relative_protocols(html, protocol) if protocol
      html
    end

    def self.translate_relative_paths(html, root_url)
      # Try out this regexp using rubular http://rubular.com/r/hiAxBNX7KE
      html.gsub(%r{(href|src)=(['"])/([^/"']([^\"']*|[^"']*))?['"]}, "\\1=\\2#{root_url}\\3\\2")
    end
    private_class_method :translate_relative_paths

    def self.translate_relative_protocols(body, protocol)
      # Try out this regexp using rubular http://rubular.com/r/0Ohk0wFYxV
      body.gsub(%r{(href|src)=(['"])//([^\"']*|[^"']*)['"]}, "\\1=\\2#{protocol}://\\3\\2")
    end
    private_class_method :translate_relative_protocols
  end
end
