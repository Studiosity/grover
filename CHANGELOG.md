# Changelog

## Unreleased
### Fixed
- Use request interception instead of data URL for middleware/raw HTML conversions

### Breaking change
- The `{{display_url}}` header/footer hack was removed in favour of passing the URL via `display_url` option
  (for middleware/raw HTML only) 

## [0.5.5](releases/tag/v0.5.5) - 2018-09-20
### Fixed
- Compare optional arguments with undefined instead of default `presence` check

## [0.5.4](releases/tag/v0.5.4) - 2018-09-20
### Fixed
- Moved Puppeteer timeout from `launch` to page `goto`

## [0.5.3](releases/tag/v0.5.3) - 2018-09-20
### Added
- Control of Puppeteer page timeout

## [0.5.2](releases/tag/v0.5.2) - 2018-09-20
### Added
- Control of Puppeteer page caching (default set to false)

## [0.5.1](releases/tag/v0.5.1) - 2018-09-15
### Added
- Support for front/back cover pages for middleware (combined with the original request PDF)

## [0.4.4](releases/tag/v0.4.4) - 2018-09-10
### Fixed
- Bug with options containing mixed symbol/string keys (and how they merge with the parsed meta options)

## [0.4.3](releases/tag/v0.4.3) - 2018-09-10
### Added
- Pass through flag to indicate to upstream middleware/app that Grover has interacted with the environment 

## [0.4.2](releases/tag/v0.4.2) - 2018-09-09
### Fixed
- Problems parsing meta tag content (with inline html templates). Use Nokogiri instead of basic regexes
- Bug where boolean/numeric type options were not passed through to PDF processor correctly (type cast)

## [0.4.1](releases/tag/v0.4.1) - 2018-09-08
### Added
- Ability to pass through options via meta tags (for use in middleware requests)

### Fixed
- Issue with `pdf_reader` on TravisCI parsing the headers/footers incorrectly (font size)  

## [0.3.1](releases/tag/v0.3.1) - 2018-08-25
### Added
- Ability to configure media emulation
- `pdf_reader` gem to better parse/test the output from Puppeteer
- Instructions in README about issues with header/footer template and display of URL

### Removed
- `activesupport` dependency in favour of implementing `strip_heredoc` in utils class

## [0.3.0](releases/tag/v0.3.0) - 2018-08-24
### Added
- Case insensitive matching for PDF file extension in middleware
- Spec tests for middleware and HTML preprocessor
- Use rubocop-rspec to lint spec tests
- Normalisation of PDF conversion options (so they match the expected format/case of Puppeteer)

### Fixed
- Lint issues raised by rubocop-rpsec

### Changed
- Moved PDF processor into Grover class to reduce unnecessary exposure of inner workings

## [0.2.2](releases/tag/v0.2.2) - 2018-08-23
### Fixed
- Bug introduced in middleware refactor

## [0.2.1](releases/tag/v0.2.1) - 2018-08-23
### Added
- HTML preprocessor to fix relative paths in source HTML

### Fixed
- Processor support for inline HTML (render via the URI rather than trying to `setContent`)

### Changed
- Minor refactor of middleware for readability 

## [0.2.0](releases/tag/v0.2.0) - 2018-08-23
### Added
- Rack middleware for rendering upstream HTML as PDF (based heavily on PDFKit middleware) 
- Allow PDF processor to handle inline HTML

### Fixed
- Use `Dir.pwd` instead of file path for default `root_path` so that when loaded as a gem the path is the current pwd

### Changed
- Minor location refactor of Grover interface

## [0.1.2](releases/tag/v0.1.2) - 2018-08-22
### Added
- Allow `root_path` for Puppeteer to be passed through Grover initialiser

## [0.1.1](releases/tag/v0.1.1) - 2018-08-22
### Fixed
- Launch browser with sandbox disabled for CI tests

## [0.1.0](releases/tag/v0.1.0) - 2018-08-22
### Added
- First pass at PDF processor
- Console script for expediting development 

## [0.0.1](releases/tag/v0.0.1) - 2018-08-22
### Added
- Initial gem framework 
