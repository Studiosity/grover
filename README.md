[![Travis Build Status](https://img.shields.io/travis/Studiosity/grover.svg?style=flat)](https://travis-ci.org/Studiosity/grover)
[![Maintainability](https://api.codeclimate.com/v1/badges/37609653789bcf2c8d94/maintainability)](https://codeclimate.com/github/Studiosity/grover/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/37609653789bcf2c8d94/test_coverage)](https://codeclimate.com/github/Studiosity/grover/test_coverage)
[![Gem Version](https://img.shields.io/gem/v/grover.svg?style=flat)](#)

# Grover

A Ruby gem to transform HTML into PDFs using [Google Puppeteer](https://github.com/GoogleChrome/puppeteer)
and [Chromium](https://www.chromium.org/Home).


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
# Grover.new accepts a URL and optional parameters for `puppeteer`
grover = Grover.new('https://google.com', page_size: 'A4')

# Get an inline PDF
pdf = grover.to_pdf

# Options can be provided through meta tags
Grover.new('<html><head><meta name="grover-page_ranges" content="1-3"')
Grover.new('<html><head><meta name="grover-margin-top" content="10px"')
# N.B. options are underscore case, and sub-options separated with a dash
# N.B. #2 all options can be overwritten, including `emulate_media` and `display_url` 
```


## Configuration
Grover can be configured to adjust the layout the resulting PDF. 
For available options, see https://github.com/GoogleChrome/puppeteer/blob/v1.7.0/docs/api.md#pagepdfoptions

Also available is the `emulate_media` option.
 
```ruby
# config/initializers/grover.rb
Grover.configure do |config|
  config.options = {
    format: 'A4',
    margin: {
      top: '5px',
      bottom: '10cm'
    },
    prefer_css_page_size: true,
    emulate_media: 'screen'
  }
end
```

#### Header/Footer templates and the 'url' tag
When using the Rack middleware, Grover passes the HTML response through to Puppeteer as inline HTML.
As such, if the header/footer flag is enabled, by default Chromium will render the url
(the entire HTML document as plain text) in the footer. Eep!

To get around this it is recommended to not use the 'url' class in either template.
Instead, place the text `{{display_url}}` where you would like the request URL to display.
Grover will look for that text, and replace it with the request URL before converting the HTML to PDF

To assist in this process, if the footer template has not been specified, the following default template is used:
```HTML
<div class='text left grow'>{{display_url}}</div>
<div class='text right'>
  <span class='pageNumber'></span>/<span class='totalPages'></span>
</div>    
```
_N.B._ the `url` class is *not* used

I've raised [an issue](https://github.com/GoogleChrome/puppeteer/issues/3133) in the Google Puppeteer project regarding
a longer term solution to this, however it would need to be resolved upstream in the Chromium project first 


## Middleware
Grover comes with a middleware that allows users to get a PDF view of
any page on your site by appending .pdf to the URL.

### Middleware Setup
**Non-Rails Rack apps**
```ruby
# in config.ru
require 'pdfkit'
use Grover::Middleware
```

**Rails apps**
```ruby
# in application.rb
require 'pdfkit'
config.middleware.use Grover::Middleware
```


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
