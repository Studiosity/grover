require 'schmooze'

class Grover
  #
  # Processor helper class for calling out to Puppeteer NodeJS library
  #
  class Processor < Schmooze::Base
    dependencies puppeteer: 'puppeteer'

    def self.launch_params
      ENV['CI'] == 'true' ? "{args: ['--no-sandbox', '--disable-setuid-sandbox']}" : ''
    end
    private_class_method :launch_params

    method :convert_pdf, Utils.squish(<<-FUNCTION)
      async (url, options) => {
        let browser;
        try {
          browser = await puppeteer.launch(#{launch_params});
          const page = await browser.newPage();
          if (url.match(/^http/i)) {
            await page.goto(url, { waitUntil: 'networkidle2' });
          } else {
            await page.setContent(url);
          }
          return await page.pdf(options);
        } finally {
          if (browser) {
            await browser.close();
          }
        }
      }
    FUNCTION
  end
end
