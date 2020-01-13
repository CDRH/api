# Apium Changelog

All notable changes to Apium will be documented in this file.

Starting from Apium v1.0.1, The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Please respect the 80-character text margin and follow the [GitHub Flavored
Markdown Spec](https://github.github.com/gfm/).

<!-- Template - Please preserve this order of sections
## [Unreleased] - Brief description
[Unreleased]: https://github.com/open-oni/open-oni/compare/v#.#.#...dev

### Fixed

### Added

### Changed

### Removed

### Migration

### Deprecated

### Contributors
-->

## [Unreleased]
[Unreleased]: https://github.com/CDRH/api/compare/v1.0.1...dev

### Added

- "api_version" added to all response "res" objects

### Changed

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

### Removed

- `["info"]["version"]` has been removed from the main page response in favor
  of "api_version" key noted in "Added" section

### Contributors

- Jessica Dussault (jduss4)

## Pre-1.0.1

This changelog does not document changes prior to version 1.0.1
