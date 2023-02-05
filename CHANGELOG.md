# Changelog

## Unreleased
- none

## [1.1.4](releases/tag/v1.1.4) - 2023-02-05
### Fixed
- [#179](https://github.com/Studiosity/grover/pull/179) Clean up temporary user data directory ([@abrom][])

## [1.1.3](releases/tag/v1.1.3) - 2023-01-21
### Added
- [#177](https://github.com/Studiosity/grover/pull/177) Add support for Ruby 3.2 ([@Yobilat][], [@abrom][])

## [1.1.2](releases/tag/v1.1.2) - 2022-09-12
### Fixed
- [#160](https://github.com/Studiosity/grover/pull/160) Support projects that are using esm instead of cjs ([@ElMassimo][])

## [1.1.1](releases/tag/v1.1.1) - 2022-01-24
### Added
- [#147](https://github.com/Studiosity/grover/pull/147) Add support for Ruby 3.1 ([@walski][])

## [1.1.0](releases/tag/v1.1.0) - 2021-12-03
### Breaking Change
- [#145](https://github.com/Studiosity/grover/pull/145) Add support for `request_timeout` and `convert_timeout` options (`timeout` option applies to conversion for Puppeteer 10.4.0+) ([@abrom][])

## [1.0.6](releases/tag/v1.0.6) - 2021-10-12
### Added
- [#131](https://github.com/Studiosity/grover/pull/131) Add support for ignoring request in addition to request.path ([@braindeaf][])

## [1.0.5](releases/tag/v1.0.5) - 2021-08-30
### Fixed
- [#128](https://github.com/Studiosity/grover/pull/128) Fix error in processor.js when using the vision_deficiency option ([@julianwegkamp][])

## [1.0.4](releases/tag/v1.0.4) - 2021-08-27
### Fixed
- [#126](https://github.com/Studiosity/grover/pull/126) Do not consider http 304 a request failure ([@lucasluitjes][])

## [1.0.3](releases/tag/v1.0.3) - 2021-08-22
### Fixed
- [#122](https://github.com/Studiosity/grover/pull/122) Fix external asset request interception with Puppeteer v10.2.0 ([@mkalygin][])

## [1.0.2](releases/tag/v1.0.2) - 2021-07-21
### Added
- [#117](https://github.com/Studiosity/grover/pull/117) Add waitForFunction support ([@rafraser][])

## [1.0.1](releases/tag/v1.0.1) - 2021-06-02
### Added
- [#112](https://github.com/Studiosity/grover/pull/112) Add flag to fail conversion if source or assets fail to load ([@deanmarano][])

## [1.0.0](releases/tag/v1.0.0) - 2021-03-01
### Added
- [#108](https://github.com/Studiosity/grover/pull/108) Add support for various methods to get feature parity with Puppeteer ([@abrom][])

## [0.14.2](releases/tag/v0.14.2) - 2021-02-22
### Added
- [#106](https://github.com/Studiosity/grover/pull/106) Add support for addStyleTag and addScriptTag ([@paresharma][])
- [#107](https://github.com/Studiosity/grover/pull/107) Add support to return the html content ([@paresharma][])

## [0.14.1](releases/tag/v0.14.1) - 2021-01-16
### Changed
- [#99](https://github.com/Studiosity/grover/pull/99) Expand required Ruby version to allow v3.0 ([@abrom][])

## [0.13.3](releases/tag/v0.13.3) - 2020-12-15
### Fixed
- [#95](https://github.com/Studiosity/grover/pull/95) Handle `nil` and empty string content edge-cases ([@abrom][])

## [0.13.2](releases/tag/v0.13.2) - 2020-12-06
### Fixed
- [#92](https://github.com/Studiosity/grover/pull/92) Fix handling of malformed worker responses ([@ckhall][])

### Added
- [#79](https://github.com/Studiosity/grover/pull/79) Add root_url option to middleware ([@anamba][])

## [0.13.1](releases/tag/v0.13.1) - 2020-08-30
### Fixed
- [#79](https://github.com/Studiosity/grover/pull/79) Fix bug in middleware where path/URI weren't restored after calling downstream ([@abrom][])

## [0.12.3](releases/tag/v0.12.3) - 2020-07-01
### Fixed
- [#70](https://github.com/Studiosity/grover/pull/70) Ensure cookies are escaped when passing cookies via middleware ([@braindeaf][])

## [0.12.2](releases/tag/v0.12.2) - 2020-06-23
### Fixed
- [#66](https://github.com/Studiosity/grover/pull/66) Fix bug masking NodeJS launch failures ([@abrom][])

### Added
- [#63](https://github.com/Studiosity/grover/pull/63) Ensure cookies from incoming request are passed to Grover via Middleware ([@braindeaf][])
- [#64](https://github.com/Studiosity/grover/pull/64) Add waitForSelector support ([@andmcgregor][])

## [0.12.1](releases/tag/v0.12.1) - 2020-05-12
### Fixed
- [#52](https://github.com/Studiosity/grover/pull/52) Fix specs to work with ImageMagick 7 ([@inspiredstuffs][])

### Changed
- [#53](https://github.com/Studiosity/grover/pull/53) Remove Schmooze in favour of built in fork ([@abrom][])

## [0.11.4](releases/tag/v0.11.4) - 2020-04-25
### Added
- [#49](https://github.com/Studiosity/grover/pull/49) Add support for passing request cookies ([@Richacinas][])

## [0.11.3](releases/tag/v0.11.3) - 2020-02-27
### Added
- [#48](https://github.com/Studiosity/grover/pull/48) Add missing option casting for `screenshot` and `viewport` attributes ([@abrom][])

### Refactor
- [#46](https://github.com/Studiosity/grover/pull/46) Extract option logic from Grover class ([@willkoehler][])

## [0.11.2](releases/tag/v0.11.2) - 2020-02-17
### Fixed
- [#43](https://github.com/Studiosity/grover/pull/43) Fix parsing of numeric type viewport options from meta tags ([@willkoehler][])

## [0.11.1](releases/tag/v0.11.1) - 2020-01-17
### Fixed
- [#41](https://github.com/Studiosity/grover/pull/41) Fix middleware cover page request env scrubbing ([@abrom][])

## [0.10.1](releases/tag/v0.10.1) - 2020-01-13
### Fixed
- [#39](https://github.com/Studiosity/grover/pull/39) Fix middleware thread safety issue ([@jnimety][])

## [0.9.2](releases/tag/v0.9.2) - 2019-12-27
### Added
- [#38](https://github.com/Studiosity/grover/pull/38) Add script execution support ([@abrom][])

## [0.9.1](releases/tag/v0.9.1) - 2019-12-09
### Added
- [#34](https://github.com/Studiosity/grover/pull/34) Add support for custom executable path ([@ryansmith23][])
- [#35](https://github.com/Studiosity/grover/pull/35) Add support for basic authentication ([@rwtaylor][])

### Changed
- [#33](https://github.com/Studiosity/grover/pull/33) Improve support for Puppeteer 2.0 (`emulateMediaType`) ([@abrom][])

## [0.8.3](releases/tag/v0.8.3) - 2019-10-31
### Added
- [#32](https://github.com/Studiosity/grover/pull/32) Add support for wait until (puppeteer load state) option ([@abrom][])

## [0.8.2](releases/tag/v0.8.2) - 2019-10-31
### Added
- [#31](https://github.com/Studiosity/grover/pull/31) Add support for launch parameter args ([@joergschiller][])

## [0.8.1](releases/tag/v0.8.1) - 2019-07-13
### Breaking change
- [#23](https://github.com/Studiosity/grover/pull/23) Drop support for Ruby 2.2 ([@abrom][])

### Added
- [#25](https://github.com/Studiosity/grover/pull/25) Add support for capturing PNG/JPEG screenshots ([@abrom][])
- [#27](https://github.com/Studiosity/grover/pull/27) Add support for PNG/JPEG middleware requests ([@abrom][])
- [#28](https://github.com/Studiosity/grover/pull/28) Add support for `viewport` options (passed in to `page.setViewport` before the page is rendered) ([@abrom][])

## [0.7.4](releases/tag/v0.7.4) - 2019-07-09
### Breaking change
- [#18](https://github.com/Studiosity/grover/pull/18) Use `GROVER_NO_SANDBOX` for disabling sandbox ([@koenhandekyn][])

## [0.7.3](releases/tag/v0.7.3) - 2019-05-23
### Fixed
- [#14](https://github.com/Studiosity/grover/pull/14) Metadata options not included if source contained *any* line starting with `http` ([@abrom][])
- [#15](https://github.com/Studiosity/grover/pull/15) Add magic comment for freezing string literals ([@abrom][])

## [0.7.2](releases/tag/v0.7.2) - 2019-01-22
### Fixed
- Better handle `null` assignment of `debug` options ([@abrom][])

## [0.7.1](releases/tag/v0.7.1) - 2019-01-22
### Added
- [#10](https://github.com/Studiosity/grover/pull/10) Ability to disable headless mode and open devtools via option parameters ([@abrom][])

## [0.6.2](releases/tag/v0.6.2) - 2018-09-20
### Fixed
- Removed memoization of path variable in middleware (on occasion a previous requests state was present) ([@abrom][])

## [0.6.1](releases/tag/v0.6.1) - 2018-09-20
### Fixed
- Use request interception instead of data URL for middleware/raw HTML conversions ([@abrom][])

### Breaking change
- The `{{display_url}}` header/footer hack was removed in favour of passing the URL via `display_url` option
  (for middleware/raw HTML only) ([@abrom][])

## [0.5.5](releases/tag/v0.5.5) - 2018-09-20
### Fixed
- Compare optional arguments with undefined instead of default `presence` check ([@abrom][])

## [0.5.4](releases/tag/v0.5.4) - 2018-09-20
### Fixed
- Moved Puppeteer timeout from `launch` to page `goto` ([@abrom][])

## [0.5.3](releases/tag/v0.5.3) - 2018-09-20
### Added
- Control of Puppeteer page timeout ([@abrom][])

## [0.5.2](releases/tag/v0.5.2) - 2018-09-20
### Added
- Control of Puppeteer page caching (default set to false) ([@abrom][])

## [0.5.1](releases/tag/v0.5.1) - 2018-09-15
### Added
- Support for front/back cover pages for middleware (combined with the original request PDF) ([@abrom][])

## [0.4.4](releases/tag/v0.4.4) - 2018-09-10
### Fixed
- Bug with options containing mixed symbol/string keys (and how they merge with the parsed meta options) ([@abrom][])

## [0.4.3](releases/tag/v0.4.3) - 2018-09-10
### Added
- Pass through flag to indicate to upstream middleware/app that Grover has interacted with the environment ([@abrom][])

## [0.4.2](releases/tag/v0.4.2) - 2018-09-09
### Fixed
- Problems parsing meta tag content (with inline html templates). Use Nokogiri instead of basic regexes ([@abrom][])
- Bug where boolean/numeric type options were not passed through to PDF processor correctly (type cast) ([@abrom][])

## [0.4.1](releases/tag/v0.4.1) - 2018-09-08
### Added
- Ability to pass through options via meta tags (for use in middleware requests) ([@abrom][])

### Fixed
- Issue with `pdf_reader` on TravisCI parsing the headers/footers incorrectly (font size) ([@abrom][])  

## [0.3.1](releases/tag/v0.3.1) - 2018-08-25
### Added
- Ability to configure media emulation ([@abrom][])
- `pdf_reader` gem to better parse/test the output from Puppeteer ([@abrom][])
- Instructions in README about issues with header/footer template and display of URL ([@abrom][])

### Removed
- `activesupport` dependency in favour of implementing `strip_heredoc` in utils class ([@abrom][])

## [0.3.0](releases/tag/v0.3.0) - 2018-08-24
### Added
- Case insensitive matching for PDF file extension in middleware ([@abrom][])
- Spec tests for middleware and HTML preprocessor ([@abrom][])
- Use rubocop-rspec to lint spec tests ([@abrom][])
- Normalisation of PDF conversion options (so they match the expected format/case of Puppeteer) ([@abrom][])

### Fixed
- Lint issues raised by rubocop-rpsec ([@abrom][])

### Changed
- Moved PDF processor into Grover class to reduce unnecessary exposure of inner workings ([@abrom][])

## [0.2.2](releases/tag/v0.2.2) - 2018-08-23
### Fixed
- Bug introduced in middleware refactor ([@abrom][])

## [0.2.1](releases/tag/v0.2.1) - 2018-08-23
### Added
- HTML preprocessor to fix relative paths in source HTML ([@abrom][])

### Fixed
- Processor support for inline HTML (render via the URI rather than trying to `setContent`) ([@abrom][])

### Changed
- Minor refactor of middleware for readability ([@abrom][])

## [0.2.0](releases/tag/v0.2.0) - 2018-08-23
### Added
- Rack middleware for rendering upstream HTML as PDF (based heavily on PDFKit middleware) ([@abrom][])
- Allow PDF processor to handle inline HTML ([@abrom][])

### Fixed
- Use `Dir.pwd` instead of file path for default `root_path` so that when loaded as a gem the path is the current pwd ([@abrom][])

### Changed
- Minor location refactor of Grover interface ([@abrom][])

## [0.1.2](releases/tag/v0.1.2) - 2018-08-22
### Added
- Allow `root_path` for Puppeteer to be passed through Grover initialiser ([@abrom][])

## [0.1.1](releases/tag/v0.1.1) - 2018-08-22
### Fixed
- Launch browser with sandbox disabled for CI tests ([@abrom][])

## [0.1.0](releases/tag/v0.1.0) - 2018-08-22
### Added
- First pass at PDF processor ([@abrom][])
- Console script for expediting development ([@abrom][])

## [0.0.1](releases/tag/v0.0.1) - 2018-08-22
### Added
- Initial gem framework ([@abrom][])

[@abrom]: https://github.com/abrom
[@koenhandekyn]: https://github.com/koenhandekyn
[@joergschiller]: https://github.com/joergschiller
[@ryansmith23]: https://github.com/ryansmith23
[@rwtaylor]: https://github.com/rwtaylor
[@jnimety]: https://github.com/jnimety
[@willkoehler]: https://github.com/willkoehler
[@Richacinas]: https://github.com/Richacinas
[@inspiredstuffs]: https://github.com/inspiredstuffs
[@braindeaf]: https://github.com/braindeaf
[@ckhall]: https://github.com/ckhall
[@anamba]: https://github.com/anamba
[@paresharma]: https://github.com/paresharma
[@deanmarano]: https://github.com/deanmarano
[@rafraser]: https://github.com/rafraser
[@mkalygin]: https://github.com/mkalygin
[@lucasluitjes]: https://github.com/lucasluitjes
[@julianwegkamp]: https://github.com/julianwegkamp
[@walski]: https://github.com/walski
[@ElMassimo]: https://github.com/ElMassimo
[@Yobilat]: https://github.com/Yobilat
