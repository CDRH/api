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

## [v2.0.0] - Nested bucket aggregation/query functionality
[v2.0.0]: https://github.com/CDRH/api/compare/v1.0.5...v2.0.0

### Added

- `api_version` added to all response `res` objects
- Support for Elasticsearch 8.5+
- User/password basic authentication support when credentials present
- Better support for nested fields
- Support for nested bucket aggregations, matching a nested value on another
  nested value. For example, `person.name[person.role#judge]` will return
  all names of persons where `role="judge"`
- Updated documentation for new features
- `track total hits` option added to ES queries, to return counts of search
   results higher than 10000

### Changed

- Gemset changed to `api-v2`
- Changes reflect new api schemas in Datura, which make heavy use of nested fields
- Added support for aggregating buckets by normalized keyword and returning
  the `top_hits` first document result for a non-normalized display. Internal logic has been changed because of nested fields, this may cause subtle differences in how facet labels are displayed
- Changes response format of `facets` key. Not only is the response format
  itself different, but there may be fewer facets returned since matching
  normalized values are combined

  From:

  ```json
  "facets": {
    "WILLA CATHER": 10,
    "Willa Cather": 50
  }
  ```

  To:

  ```json
  "facets": {
    "willa cather": { "num" : 60, source: "Willa Cather" }
  }
  ```

### Migration

- Add nested facets as described above, if desired
- Orchid apps that connect to the API should use `facet_limit` instead of `facet_num` in options
- In the config files of your Datura repos, (`private.yml` or `public.yml`, set
  the api to `"api_version": "2.0"` to take advantage of new bucket aggregation 
  functionality (or `"api_version": "1.0"` for legacy repos that have not been 
  updated for the new schema). Please note that a running API index can only use 
  one ES index at a time, and each ES index is restricted to one version of the
  schema. See [new schema (2.0)
  documentation](https://github.com/CDRH/datura/docs/schema_v2.md).
- Connect to Elasticsearch 8.5 or later
- If you are using ES with security enabled, you must configure credentials
  with Rails in the API repo. See
  https://guides.rubyonrails.org/v6.1/security.html. To configure with VSCode
  editor run `EDITOR="code --wait" rails credentials:edit` and add to the
  secrets file and then close the window to save.
  Do not commit `config/master.key` (it should be in `.gitignore`)

```
elasticsearch:
  user: username
  password: *****
```

## [v1.0.5] - API v1 on Ruby 3.1.6, Rails 6.1.7
[v1.0.5]: https://github.com/CDRH/api/compare/v1.0.4...v1.0.5

### Changed
- Ruby 3.1.6
- Rails 6.1.7

## [v1.0.4](https://github.com/CDRH/api/compare/v1.0.3...v1.0.4) - Updates & license

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
