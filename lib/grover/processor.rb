require 'schmooze'

class Grover
  #
  # Processor helper class for calling out to Puppeteer NodeJS library
  #
  class Processor < Schmooze::Base
    dependencies puppeteer: 'puppeteer'

    method :convert_pdf, Utils.squish(<<-FUNCTION)
      async (url, options) => {
        let browser;
        try {
          browser = await puppeteer.launch();
          const page = await browser.newPage();
          await page.goto(url, { waitUntil: 'networkidle2' });
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
