# Apium Changelog

All notable changes to Apium will be documented in this file.

Starting from Apium v1.0.1, The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Please respect the 80-character text margin and follow the [GitHub Flavored
Markdown Spec](https://github.github.com/gfm/).

<!-- Template - Please preserve this order of sections
## [Unreleased] - Brief description
[Unreleased]: https://github.com/CDRH/api/compare/v#.#.#...dev

### Fixed

### Added

### Changed

### Removed

### Migration

### Deprecated

### Contributors
-->

## [Unreleased] - updates in preparation for Habeas release
[Unreleased]: https://github.com/CDRH/api/compare/v1.0.4...dev

### Added
- "api_version" added to all response "res" objects

### Changed
- upgraded to Rails 6
- Added support for aggregating buckets by normalized keyword and returning
  the "top_hits" first document result for a non-normalized display
- Changes response format of `facets` key
  
  From:
  ```
  "facets": {
    "WILLA CATHER": 10,
    "Willa Cather": 50
  }
  ```
  To:
  ```
  "facets": {
    "willa cather": { "num" : 60, source: "Willa Cather" }
  }
  ```
  Not only is the response format itself different, but there may be fewer
  facets returned since normalized values which match are combined

## [v1.0.4](https://github.com/CDRH/api/compare/v1.0....v1.0.4) - Updates & license

### Changed
- Updated Ruby version, gems (which addresses mimemagic dependency problem), and
license added

### Added
- Documentation on facets and highlighting

## [v1.0.3](https://github.com/CDRH/api/compare/v1.0.2...v1.0.3) - gem updates

### Changed
- updates to rails and other gems

## [v1.0.2](https://github.com/CDRH/api/compare/v1.0.1...v1.0.2) - escapes and sorting

### Fixed
- question mark and asterisk behavior in queries
- order of expected, actual in tests
- sort behavior for relevancy

### Added
- support for multivalued and nested field sorting
- documentation moved back into apium from henbit location in order to version it with software

### Changed
- ruby, rails, and other gem versions

## [v1.0.1](https://github.com/CDRH/api/compare/v1.00...v1.0.1) - version 1.0.1

### Changed
- ruby, rails, and other gem versions
- version moved to initializer

## [v1.0.0](https://github.com/CDRH/api/tree/v1.0.0) - Initial Launch

### Contributors

- Jessica Dussault (jduss4)

