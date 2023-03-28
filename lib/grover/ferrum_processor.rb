require "ferrum"
require "tempfile"
require "base64"

class Grover
  class FerrumProcessor
    def convert(method, html, options)
      page = browser.create_page
      page.content = html
      Base64.decode64(page.pdf)
    ensure
      browser.quit
    end

    private

    def browser
      @browser ||= Ferrum::Browser.new
    end
  end
end

