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

const fs = require('fs');
const os = require('os');
const path = require('path');

const _processPage = (async (convertAction, urlOrHtml, options) => {
  let browser, page, browserWsEndpoint, errors = [], tmpDir;

  try {
    // Configure puppeteer debugging options
    const debug = options.debug; delete options.debug;
    browserWsEndpoint = options.browserWsEndpoint; delete options.browserWsEndpoint;
    if (typeof browserWsEndpoint === "string") {
      const connectParams = {
        browserWSEndpoint: browserWsEndpoint,
      };

      browser = await puppeteer.connect(connectParams);
    } else {
      tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'grover-'));

      const launchParams = {
        args: process.env.GROVER_NO_SANDBOX === 'true' ? ['--no-sandbox', '--disable-setuid-sandbox'] : [],
        userDataDir: tmpDir
      };
  
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
    }

    page = await browser.newPage();

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
    let requestTimeout = options.requestTimeout; delete options.requestTimeout;
    if (requestTimeout === undefined) requestTimeout = options.timeout;
    if (requestTimeout !== undefined) {
      requestOptions.timeout = requestTimeout;
    }

    // Setup user agent (if provided)
    const userAgent = options.userAgent; delete options.userAgent;
    if (userAgent !== undefined) {
      await page.setUserAgent(userAgent);
    }

    // Setup viewport options (if provided)
    const viewport = options.viewport; delete options.viewport;
    if (viewport !== undefined) {
      await page.setViewport(viewport);
    }

    // If specified, emulate the media type
    const emulateMedia = options.emulateMedia; delete options.emulateMedia;
    if (emulateMedia !== undefined) {
      if (typeof page.emulateMediaType === 'function') {
        await page.emulateMediaType(emulateMedia);
      } else {
        await page.emulateMedia(emulateMedia);
      }
    }

    // Emulate the media features, if specified
    const mediaFeatures = options.mediaFeatures; delete options.mediaFeatures;
    if (Array.isArray(mediaFeatures)) {
      await page.emulateMediaFeatures(mediaFeatures);
    }

    // Emulate timezone (if provided)
    const timezone = options.timezone; delete options.timezone;
    if (timezone !== undefined) {
      await page.emulateTimezone(timezone);
    }

    // Bypass CSP (content security policy), if provided
    const bypassCSP = options.bypassCSP; delete options.bypassCSP;
    if (bypassCSP !== undefined) {
      await page.setBypassCSP(bypassCSP);
    }

    // Add extra HTTP headers (if provided)
    const extraHTTPHeaders = options.extraHTTPHeaders; delete options.extraHTTPHeaders;
    if (extraHTTPHeaders !== undefined) {
      await page.setExtraHTTPHeaders(extraHTTPHeaders);
    }

    // Set geolocation (if provided)
    const geolocation = options.geolocation; delete options.geolocation;
    if (geolocation !== undefined) {
      await page.setGeolocation(geolocation);
    }

    const raiseOnRequestFailure = options.raiseOnRequestFailure; delete options.raiseOnRequestFailure;
    if (raiseOnRequestFailure) {
      page.on('requestfinished', (request) => {
        if (request.response() && !(request.response().ok() || request.response().status() === 304) && !request.redirectChain().length > 0) {
          errors.push(request);
        }
      });
      page.on('requestfailed', (request) => {
        errors.push(request);
      });
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
      let htmlIntercepted = false;
      page.on('request', request => {
        // We only want to intercept the first request - ie our HTML
        if (htmlIntercepted)
          request.continue();
        else {
          htmlIntercepted = true
          request.respond({ body: urlOrHtml === '' ? ' ' : urlOrHtml });
        }
      });
      const displayUrl = options.displayUrl; delete options.displayUrl;
      await page.goto(displayUrl || 'http://example.com', requestOptions);
    }

    // add styles (if provided)
    const styleTagOptions = options.styleTagOptions; delete options.styleTagOptions;
    if (Array.isArray(styleTagOptions)) {
      for (const styleTagOption of styleTagOptions) {
        await page.addStyleTag(styleTagOption);
      }
    }

    // add scripts (if provided)
    const scriptTagOptions = options.scriptTagOptions; delete options.scriptTagOptions;
    if (Array.isArray(scriptTagOptions)) {
      for (const scriptTagOption of scriptTagOptions) {
        await page.addScriptTag(scriptTagOption);
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
      await page.waitForSelector(waitForSelector, waitForSelectorOptions);
    }

    // If specified, wait for function
    const waitForFunction = options.waitForFunction; delete options.waitForFunction;
    const waitForFunctionOptions = options.waitForFunctionOptions; delete options.waitForFunctionOptions;
    if (waitForFunction !== undefined) {
      await page.waitForFunction(waitForFunction, waitForFunctionOptions);
    }

    // If specified, wait for timeout
    const waitForTimeout = options.waitForTimeout; delete options.waitForTimeout;
    if (waitForTimeout !== undefined) {
      await page.waitForTimeout(waitForTimeout);
    }

    // Emulate vision deficiency (if provided)
    const visionDeficiency = options.visionDeficiency; delete options.visionDeficiency;
    if (visionDeficiency !== undefined) {
      await page.emulateVisionDeficiency(visionDeficiency);
    }

    // If specified, focus on the specified selector
    const focusSelector = options.focus; delete options.focus;
    if (focusSelector !== undefined) {
      await page.focus(focusSelector);
    }

    // If specified, hover on the specified selector
    const hoverSelector = options.hover; delete options.hover;
    if (hoverSelector !== undefined) {
      await page.hover(hoverSelector);
    }

    if (errors.length > 0) {
      function RequestFailedError(errors) {
        this.name = "RequestFailedError";
        this.message = errors.map(e => {
          if (e.failure()) {
            return e.failure().errorText + " at " + e.url();
          } else if (e.response() && e.response().status()) {
            return e.response().status() + " " + e.url();
          } else {
            return "UnknownError " + e.url()
          }
        }).join("\n");
      }
      RequestFailedError.prototype = Error.prototype;
      throw new RequestFailedError(errors);
    }

    // Setup conversion timeout
    if (options.convertTimeout !== undefined) {
      options.timeout = options.convertTimeout;
      delete options.convertTimeout;
    }

    // If we're running puppeteer in headless mode, return the converted PDF
    if (debug === undefined || (typeof debug === 'object' && (debug.headless === undefined || debug.headless))) {
      return await page[convertAction](options);
    }
  } finally {
    await page.close();
    if (browser) {
      if (browserWsEndpoint) {
        await browser.disconnect();
      } else {
        await browser.close();
      }
    }

    try {
      if (tmpDir) fs.rmSync(tmpDir, { recursive: true });
    } catch { }
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
