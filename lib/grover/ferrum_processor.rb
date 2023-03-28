require "ferrum"
require "base64"

class Grover
  class FerrumProcessor
    def convert(method, html, options)
      page = browser.create_page
      page.content = html

      sleep 0.5 # give network requests time to start
      browser.network.wait_for_idle

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

