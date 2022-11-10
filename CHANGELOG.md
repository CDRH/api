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

## [2.0.0] - new nested bucket aggregation/query functionality for Habeas release

[unreleased]: https://github.com/CDRH/api/compare/v1.0.4...dev

### Added

- "api_version" added to all response "res" objects
- support for elasticsearch 8.5
- user/password basic authentication with ES 8.5, when querying the index or posting from Datura
- better support for nested fields
- support for nested bucket aggregations, matching a nested value on another nested value. `person.name[person.role#judge]` will return all names of persons where role="judge".
- "api_version" added to all response "res" objects

### Changed

- upgraded to Rails 6.1.7 and Ruby 3
- changes reflect new api schemas in Datura, which make heavy use of nested fields
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

### Changed

- upgraded to Rails 6.1.7 and Ruby 3
- changes reflect new api schemas in Datura, which make heavy use of nested fields

### Migration

- in the config files of your Datura repos, (`private.yml` or `public.yml`, set the api to `"api_version": "2.0"` to take advantage of new bucket aggregation functionality (or `"api_version": "1.0"` for legacy repos that have not been updated for the new schema). Please note that a running API index can only use one ES index at a time, and each ES index is restricted to one version of the schema. See new schema (2.0) documentation [here](https://github.com/CDRH/datura/docs/schema_v2.md).
- Use Elasticsearch 8.5 or later. See [dev docs instructions](https://github.com/CDRH/cdrh_dev_docs/blob/update_elasticsearch_documentation/publishing/2_basic_requirements.md#downloading-elasticsearch).
- If you are using ES with security enabled, you must configure credentials with Rails in the API repo. See https://guides.rubyonrails.org/v6.1/security.html. Configure the VSCode editor. Run `EDITOR="code --wait" rails credentials:edit` and add

```
elasticsearch:
  user: username
  password: *****
```

to the secrets file and then close the window to save. Do not commit `config/master.key` (it should be in `gitignore`)

- Orchid apps that connect to the API should use `facet_limit` instead of `facet_num` in options.
- Add nested facets as described above, if desired

### Migration

- in Datura repos config `private.yml` api to `"api_version": "2.0"` to take advantage of new bucket aggregation functionality (or `"api_version": "1.0"` for legacy repos that have not been updated for the new schema). Please note that a running API index can only use one ES index at a time, and each ES index is restricted to one version of the schema. See new schema (2.0) documentation [here](https://github.com/CDRH/datura/docs/schema_v2.md)
- Use Elasticsearch 8.5 or later. See [dev docs instructions](https://github.com/CDRH/cdrh_dev_docs/blob/update_elasticsearch_documentation/publishing/2_basic_requirements.md#downloading-elasticsearch).
- If you are using ES with security enabled, you must configure credentials with Rails in the API repo. See https://guides.rubyonrails.org/v6.1/security.html. Configure the VSCode editor. Run `EDITOR="code --wait" rails credentials:edit` and add

```
elasticsearch:
  user: username
  password: *****
```

to the secrets file and then close the window to save. Do not commit `config/master.key` (it should be in `gitignore`)

- Orchid apps that connect to the API should use `facet_limit` instead of `facet_num` in options.
- Add nested facets as described above, if desired.

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
