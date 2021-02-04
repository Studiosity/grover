// Setup imports
try {
  const Module = require('module');
  // resolve puppeteer from the CWD instead of where this script is located
  var puppeteer = require(require.resolve('puppeteer', { paths: Module._nodeModulePaths(process.cwd()) }));
} catch (e) {
  process.stdout.write(JSON.stringify(['err', e.toString()]));
  process.stdout.write("\n");
  process.exit(1);
}
process.stdout.write("[\"ok\"]\n");

const _processPage = (async (convertAction, urlOrHtml, options) => {
  let browser;
  try {
    const launchParams = {
      args: process.env.GROVER_NO_SANDBOX === 'true' ? ['--no-sandbox', '--disable-setuid-sandbox'] : []
    };

    // Configure puppeteer debugging options
    const debug = options.debug; delete options.debug;
    if (typeof debug === 'object' && !!debug) {
      if (debug.headless !== undefined) { launchParams.headless = debug.headless; }
      if (debug.devtools !== undefined) { launchParams.devtools = debug.devtools; }
    }

    // Configure additional launch arguments
    const args = options.launchArgs; delete options.launchArgs;
    if (Array.isArray(args)) {
      launchParams.args = launchParams.args.concat(args);
    }

    // Set executable path if given
    const executablePath = options.executablePath; delete options.executablePath;
    if (executablePath) {
      launchParams.executablePath = executablePath;
    }

    // Launch the browser and create a page
    browser = await puppeteer.launch(launchParams);
    const page = await browser.newPage();

    // Basic auth
    const username = options.username; delete options.username
    const password = options.password; delete options.password
    if (username !== undefined && password !== undefined) {
      await page.authenticate({ username, password });
    }

    // Setting cookies
    const cookies = options.cookies; delete options.cookies
    if (Array.isArray(cookies)) {
      await page.setCookie(...cookies);
    }

    // Set caching flag (if provided)
    const cache = options.cache; delete options.cache;
    if (cache !== undefined) {
      await page.setCacheEnabled(cache);
    }

    // Setup timeout option (if provided)
    let requestOptions = {};
    const timeout = options.timeout; delete options.timeout;
    if (timeout !== undefined) {
      requestOptions.timeout = timeout;
    }

    // Setup viewport options (if provided)
    const viewport = options.viewport; delete options.viewport;
    if (viewport !== undefined) {
      await page.setViewport(viewport);
    }

    const waitUntil = options.waitUntil; delete options.waitUntil;
    if (urlOrHtml.match(/^http/i)) {
      // Request is for a URL, so request it
      requestOptions.waitUntil = waitUntil || 'networkidle2';
      await page.goto(urlOrHtml, requestOptions);
    } else {
      // Request is some HTML content. Use request interception to assign the body
      requestOptions.waitUntil = waitUntil || 'networkidle0';
      await page.setRequestInterception(true);
      page.once('request', request => {
        request.respond({ body: urlOrHtml === '' ? ' ' : urlOrHtml });
        // Reset the request interception
        // (we only want to intercept the first request - ie our HTML)
        page.on('request', request => request.continue());
      });
      const displayUrl = options.displayUrl; delete options.displayUrl;
      await page.goto(displayUrl || 'http://example.com', requestOptions);
    }
    await page.evaluateHandle('document.fonts.ready');

    // If specified, emulate the media type
    const emulateMedia = options.emulateMedia; delete options.emulateMedia;
    if (emulateMedia !== undefined) {
      if (typeof page.emulateMediaType == 'function') {
        await page.emulateMediaType(emulateMedia);
      } else {
        await page.emulateMedia(emulateMedia);
      }
    }

    // If specified, evaluate script on the page
    const executeScript = options.executeScript; delete options.executeScript;
    if (executeScript !== undefined) {
      await page.evaluate(executeScript);
    }

    // If specified, wait for selector
    const waitForSelector = options.waitForSelector; delete options.waitForSelector;
    const waitForSelectorOptions = options.waitForSelectorOptions; delete options.waitForSelectorOptions;
    if (waitForSelector !== undefined) {
      await page.waitForSelector(waitForSelector, waitForSelectorOptions)
    }

    // If we're running puppeteer in headless mode, return the converted PDF
    if (debug === undefined || (typeof debug === 'object' && (debug.headless === undefined || debug.headless))) {
      return await page[convertAction](options);
    }
  } finally {
    if (browser) {
      await browser.close();
    }
  }
});

function _handleError(error) {
  if (error instanceof Error) {
    process.stdout.write(
      JSON.stringify(['err', error.toString().replace(new RegExp('^' + error.name + ': '), ''), error.name])
    );
  } else {
    process.stdout.write(JSON.stringify(['err', error.toString()]));
  }
  process.stdout.write("\n");
}

// Interface for communicating between Ruby processor and Node processor
require('readline').createInterface({
  input: process.stdin,
  terminal: false,
}).on('line', function(line) {
  try {
    Promise.resolve(_processPage.apply(null, JSON.parse(line)))
      .then(function (result) {
        process.stdout.write(JSON.stringify(['ok', result]));
        process.stdout.write("\n");
      })
      .catch(_handleError);
  } catch(error) {
    _handleError(error);
  }
});
