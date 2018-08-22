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


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
