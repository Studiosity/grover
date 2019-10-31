[![Travis Build Status](https://img.shields.io/travis/Studiosity/grover.svg?style=flat)](https://travis-ci.org/Studiosity/grover)
[![Maintainability](https://api.codeclimate.com/v1/badges/37609653789bcf2c8d94/maintainability)](https://codeclimate.com/github/Studiosity/grover/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/37609653789bcf2c8d94/test_coverage)](https://codeclimate.com/github/Studiosity/grover/test_coverage)
[![Gem Version](https://badge.fury.io/rb/grover.svg)](https://badge.fury.io/rb/grover)

# Grover

A Ruby gem to transform HTML into PDFs, PNGs or JPEGs using [Google Puppeteer](https://github.com/GoogleChrome/puppeteer)
and [Chromium](https://www.chromium.org/Home).

![Grover](/Grover.jpg "Grover")

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grover'
```

### Google Puppeteer
```bash
npm install puppeteer
```


## Usage
```ruby
# Grover.new accepts a URL or inline HTML and optional parameters for Puppeteer
grover = Grover.new('https://google.com', format: 'A4')

# Get an inline PDF
pdf = grover.to_pdf

# Get a screenshot
png = grover.to_png
jpeg = grover.to_jpeg 

# Options can be provided through meta tags
Grover.new('<html><head><meta name="grover-page_ranges" content="1-3"')
Grover.new('<html><head><meta name="grover-margin-top" content="10px"')
```

N.B.
* options are underscore case, and sub-options separated with a dash
* all options can be overwritten, including `emulate_media` and `display_url`

### From a view template
It's easy to render a normal Rails view template as a PDF, using Rails' [`render_to_string`](https://api.rubyonrails.org/classes/AbstractController/Rendering.html#method-i-render_to_string):

```ruby
html = MyController.new.render_to_string({
  template: 'controller/view',
  layout: 'my_layout',
  locals: { :@instance_var => ... }
})
pdf = Grover.new(html, grover_options).to_pdf
```

### Relative paths
If calling Grover directly (not through middleware) you will need to either specify a `display_url` or modify your
HTML by converting any relative paths to absolute paths before passing to Grover.

This can be achieved using the HTML pre-processor helper:

```ruby
absolute_html = Grover::HTMLPreprocessor.process relative_html, 'http://my.server/', 'http'
```

This is important because Chromium will try and resolve any relative paths via the display url host. If not provided,
the display URL defaults to `http://example.com`.

#### Why would you pre-process the HTML rather than just use the `display_url`
There are many scenarios where specifying a different host of relative paths would be preferred. For example, your
server might be behind a NAT gateway and the display URL in front of it. The display URL might be shown in the
header/footer, and as such shouldn't expose details of your private network.

If you run into trouble, take a look at the [debugging](#debugging) section below which would allow you to inspect the
page content and devtools.


## Configuration
Grover can be configured to adjust the layout of the resulting PDF/image.

For available PDF options, see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions

Also available are the `emulate_media`, `cache`, `viewport`, `timeout` and `launch_args` options.

```ruby
# config/initializers/grover.rb
Grover.configure do |config|
  config.options = {
    format: 'A4',
    margin: {
      top: '5px',
      bottom: '10cm'
    },
    viewport: {
      width: 640,
      height: 480
    },
    prefer_css_page_size: true,
    emulate_media: 'screen',
    cache: false,
    timeout: 0, # Timeout in ms. A value of `0` means 'no timeout'
    launch_args: ['--font-render-hinting=medium'] 
  }
end
```

For available PNG/JPEG options, see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagescreenshotoptions

Note that by default the `full_page` option is set to false and you will get a 800x600 image. You can either specify
the image size using the `clip` options, or capture the entire page with `full_page` set to `true`.

For `viewport` options, see https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagesetviewportviewport

For `launch_args` options, see http://peter.sh/experiments/chromium-command-line-switches/
Launch parameter args can also be provided using a meta tag:

```html
<meta name="grover-launch_args" content="['--disable-speech-api']" />
``` 

#### Page URL for middleware requests (or passing through raw HTML)
If you want to have the header or footer display the page URL, Grover requires that this is passed through via the
`display_url` option. This is because the page URL is not available in the raw HTML!

For Rack middleware conversions, the original request URL (without the .pdf extension) will be passed through and
assigned to `display_url` for you. You can of course override this by using a meta tag in the downstream HTML response.

For raw HTML conversions, if the `display_url` is not provided `http://example.com` will be used as the default.

#### Header and footer templates
Should be valid HTML markup with following classes used to inject printing values into them:
* `date` formatted print date
* `title` document title
* `url` document location
* `pageNumber` current page number
* `totalPages` total pages in the document


## Middleware
Grover comes with a middleware that allows users to get a PDF, PNG or JPEG view of
any page on your site by appending .pdf, .png or .jpeg/.jpg to the URL.

### Middleware Setup
**Non-Rails Rack apps**
```ruby
# in config.ru
require 'grover'
use Grover::Middleware
```

**Rails apps**
```ruby
# in application.rb
require 'grover'
config.middleware.use Grover::Middleware
```

N.B. by default PNG and JPEG are not modified in the middleware to prevent breaking standard behaviours.
To enable them, there are configuration options for each image type as well as an option to disable the PDF middleware
(on by default).

If either of the image handling middleware options are enabled, the [ignore_path](#ignore_path) should also
be configured, otherwise assets are likely to be handled which would likely result in 404 responses.  

```ruby
# config/initializers/grover.rb
Grover.configure do |config|
  config.use_png_middleware = true
  config.use_jpeg_middleware = true
  config.use_pdf_middleware = false
end
```

#### ignore_path
The `ignore_path` configuration option can be used to tell Grover's middleware whether it should handle/modify
the response. There are three ways to set up the `ignore_path`:
 * a `String` which matches the start of the request path.
 * a `Regexp` which could match any part of the request path.
 * a `Proc` which accepts the request path as a parameter.

```ruby
# config/initializers/grover.rb
Grover.configure do |config|
  # assigning a String
  config.ignore_path = '/assets/'
  # matches `www.example.com/assets/foo.png` and not `www.example.com/bar/assets/foo.png`

  # assigning a Regexp
  config.ignore_path = /my\/path/
  # matches `www.example.com/foo/my/path/bar.png` 

  # assigning a Proc
  config.ignore_path = ->(path) do
    /\A\/foo\/.+\/[0-9]+\.png\z/.match path 
  end
  # matches `www.example.com/foo/bar/123.png`
end
```

## Cover pages
Since the header/footer for Puppeteer is configured globally, displaying of front/back cover
pages (with potentially different headers/footers etc) is not possible.

To get around this, Grover's middleware allows you to specify relative paths for the cover page contents
via `front_cover_path` and `back_cover_path` either via the global configuration, or via meta tags.
These paths (with query parameters) are then requested from the downstream app.

The cover pages are converted to PDF in isolation, and then combined together with the original PDF response,
before being returned back up through the Rack stack.

_N.B_ To simplify things, the same request method and body are used for the cover page requests.

```ruby
# config/initializers/grover.rb
Grover.configure do |config|
  config.options = {
    front_cover_path: '/some/global/cover/page?foo=bar'
  }
end
```

Or via the meta tags in the original response:
```HTML
<html>
  <head>
    <meta name="grover-back_cover_path" content="/back/cover/page?bar=baz" />
  </head>
  ...
</html>
```

## Running on Heroku

To run Grover (Puppeteer) on Heroku there are two steps.

First add the buildpack for puppeteer by running the following command on your heroku applicaiton.
Make sure the the puppeteer buildpack runs before the main ruby buildpack.

    heroku buildpacks:add jontewks/puppeteer --index=1 [--remote yourappname]

Next, tell Grover to run Puppeteer in the "no-sandbox" mode by setting an ENV variable
`GROVER_NO_SANDBOX=true` on your app dyno. Be carefull to make sure that you trust all
the HTML/JS that you provide to Grover.

    heroku config:set GROVER_NO_SANDBOX=true [--remote yourappname]

## Debugging
If you're having trouble with converting the HTML content, you can enable some debugging options to help. These can be
enabled as global options via `Grover.configure`, by passing through to the Grover initializer, or using meta tag
options.

```ruby
debug: {
  headless: false,  # Default true. When set to false, the Chromium browser will be displayed
  devtools: true    # Default false. When set to true, the browser devtools will be displayed.
}
```

N.B.
* The headless option disabled is not compatible with exporting of the PDF.
* If showing the devtools, the browser will halt resulting in a navigation timeout


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Studiosity/grover.

Note that spec tests are appreciated to minimise regressions. Before submitting a PR, please ensure that:

```bash
$ rspec
```
and

```bash
$ rubocop
```
both succeed


## Special mention
Thanks are given to the great work done in the [PDFKit project](https://github.com/pdfkit/pdfkit).
The middleware and HTML preprocessing components were used heavily in the implementation of Grover.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
