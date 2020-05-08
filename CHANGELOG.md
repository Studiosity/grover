# Changelog

## Unreleased
### Fixed
- [#52](https://github.com/Studiosity/grover/pull/52) Fix specs to work with ImageMagick 7 ([@inspiredstuffs][])

## [0.11.4](releases/tag/v0.11.4) - 2020-04-25
### Added
- [#49](https://github.com/Studiosity/grover/pull/49) Add support for passing request cookies ([@Richacinas][])

## [0.11.3](releases/tag/v0.11.3) - 2020-02-27
### Added
- [#48](https://github.com/Studiosity/grover/pull/48) Add missing option casting for `screenshot` and `viewport` attributes

### Refactor
- [#46](https://github.com/Studiosity/grover/pull/46) Extract option logic from Grover class ([@willkoehler][])

## [0.11.2](releases/tag/v0.11.2) - 2020-02-17
### Fixed
- [#43](https://github.com/Studiosity/grover/pull/43) Fix parsing of numeric type viewport options from meta tags ([@willkoehler][])

## [0.11.1](releases/tag/v0.11.1) - 2020-01-17
### Fixed
- [#41](https://github.com/Studiosity/grover/pull/41) Fix middleware cover page request env scrubbing

## [0.10.1](releases/tag/v0.10.1) - 2020-01-13
### Fixed
- [#39](https://github.com/Studiosity/grover/pull/39) Fix middleware thread safety issue ([@jnimety][]) 

## [0.9.2](releases/tag/v0.9.2) - 2019-12-27
### Added
- [#38](https://github.com/Studiosity/grover/pull/38) Add script execution support

## [0.9.1](releases/tag/v0.9.1) - 2019-12-09
### Added
- [#34](https://github.com/Studiosity/grover/pull/34) Add support for custom executable path ([@ryansmith23][])
- [#35](https://github.com/Studiosity/grover/pull/35) Add support for basic authentication ([@rwtaylor][])

### Changed
- [#33](https://github.com/Studiosity/grover/pull/33) Improve support for Puppeteer 2.0 (`emulateMediaType`)

## [0.8.3](releases/tag/v0.8.3) - 2019-10-31
### Added
- [#32](https://github.com/Studiosity/grover/pull/32) Add support for wait until (puppeteer load state) option

## [0.8.2](releases/tag/v0.8.2) - 2019-10-31
### Added
- [#31](https://github.com/Studiosity/grover/pull/31) Add support for launch parameter args ([@joergschiller][])

## [0.8.1](releases/tag/v0.8.1) - 2019-07-13
### Breaking change
- [#23](https://github.com/Studiosity/grover/pull/23) Drop support for Ruby 2.2

### Added
- [#25](https://github.com/Studiosity/grover/pull/25) Add support for capturing PNG/JPEG screenshots
- [#27](https://github.com/Studiosity/grover/pull/27) Add support for PNG/JPEG middleware requests
- [#28](https://github.com/Studiosity/grover/pull/28) Add support for `viewport` options (passed in to `page.setViewport` before the page is rendered)

## [0.7.4](releases/tag/v0.7.4) - 2019-07-09
### Breaking change
- [#18](https://github.com/Studiosity/grover/pull/18) Use `GROVER_NO_SANDBOX` for disabling sandbox ([@koenhandekyn][])
 
## [0.7.3](releases/tag/v0.7.3) - 2019-05-23
### Fixed
- [#14](https://github.com/Studiosity/grover/pull/14) Metadata options not included if source contained *any* line starting with `http` 
- [#15](https://github.com/Studiosity/grover/pull/15) Add magic comment for freezing string literals

## [0.7.2](releases/tag/v0.7.2) - 2019-01-22
### Fixed
- Better handle `null` assignment of `debug` options

## [0.7.1](releases/tag/v0.7.1) - 2019-01-22
### Added
- [#10](https://github.com/Studiosity/grover/pull/10) Ability to disable headless mode and open devtools via option parameters

## [0.6.2](releases/tag/v0.6.2) - 2018-09-20
### Fixed
- Removed memoization of path variable in middleware (on occasion a previous requests state was present)

## [0.6.1](releases/tag/v0.6.1) - 2018-09-20
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

[@koenhandekyn]: https://github.com/koenhandekyn
[@joergschiller]: https://github.com/joergschiller
[@ryansmith23]: https://github.com/ryansmith23
[@rwtaylor]: https://github.com/rwtaylor 
[@jnimety]: https://github.com/jnimety
[@willkoehler]: https://github.com/willkoehler
[@Richacinas]: https://github.com/Richacinas
[@inspiredstuffs]: https://github.com/inspiredstuffs 
