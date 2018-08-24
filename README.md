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

```


## Configuration
Grover can be configured to adjust the layout the resulting PDF. 
For available options, see https://github.com/GoogleChrome/puppeteer/blob/v1.7.0/docs/api.md#pagepdfoptions
 
```ruby
# config/initializers/grover.rb
Grover.configure do |config|
  config.options = {
    format: 'A4',
    margin: {
      top: '5px',
      bottom: '10cm'
    },
    prefer_css_page_size: true
  }
end
```


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
