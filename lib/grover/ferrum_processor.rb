require "ferrum"

class Grover
  class FerrumProcessor
    def convert(method, html, options)
      page = browser.create_page
      page.content = html

      sleep 0.5 # give network requests time to start
      browser.network.wait_for_idle

      page.pdf(encoding: :binary)
    ensure
      browser.quit
    end

    private

    def browser
      @browser ||= Ferrum::Browser.new
    end
  end
end

