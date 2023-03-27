require "ferrum"
require "tempfile"
require "base64"

class Grover
  class FerrumProcessor
    def convert(method, html, options)
      browser = Ferrum::Browser.new
      Tempfile.open(%w[page .html]) do |file|
        file.write(html)
        browser.go_to("file://#{file.path}")
      end
      Base64.decode64(browser.pdf)
    ensure
      browser.quit
    end
  end
end

