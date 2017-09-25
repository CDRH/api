# api
API to access all public Center for Digital Research in the Humanities resources

## item query

- [Facets](#facets)
- [Field List](#field-list)
- [Filters](#filters)
- [Highlighting](#highlighting)
- [Sorting](#sorting)
- [Start and Rows](#start-and-rows)
- [Text Searches](#text-search)

### facets

_Lists number of documents matching keyword fields_

Defaults:

- no defaults

__Standard fields__

`facet[]=keyword_field`

```
facet[]=category
facet[]=category&facet[]=title
```

__Nested fields__

`facet[]=nested_field.keyword_field`

```
facet[]=creator.name
facet[]=creator.name&facet[]=creator.role
```

__Date ranges__ (currently supports days or years)

`facet[]=date_field.range`

```
facet[]=date.year
  #=> { 1889 : 10, 1890 : 20 }

facet[]=date
  #=> { 01-02-1889 : 2, 03-04-1889 : 8 }
```

Number of facets returned and sorting alphabetically (by default sorts by count)

`facet_num=number&facet_sort=term|direction`

```
facet_num=100
facet_sort=term|asc

facet_num=30&facet_sort=term|desc
```

__Sorting facets__

Defaults:

- score|desc

Always defaults to score (_count) and descending. If you wish to sort alphabetically, add "term" and a direction. If you wish to sort score ascending, use "score" and a direction.

`facet_sort=type|direction`

```
facet_sort=term|desc
facet_sort=score|asc
```

### field list

_The fields returned by a query_

Defaults:

- returns all possible fields

Restrict the fields displayed per document in the response. Use `!` to exclude a field. Wildcards in fieldnames supported.

`fl=yes,!no`

```
fl=title,!date*,date_written
```

### filters

_Filters by keyword field across the possible documents_

Defaults:

- no filters applied except `_type` for collection

__Standard fields__

`f[]=field|type`

```
f[]=category|Writings
f[]=category|Writings&f[]=format|manuscript
```

__Nested fields__

`f[]=nested.keyword|type`

```
f[]=creator.name|Cather, Willa
f[]=contributor.role|Editor
```

__Date field__

If given one date, will use it has both start and end.

Can give year range or specify date range

`f[]=field|range_start|(range_end)`

```bash
f[]=date|1884
  #=> 01-01-1884 to 12-31-1884
f[]=date|1884|1887
  #=> 01-01-1884 to 12-31-1887

f[]=date|1884-02-01|1887-03-01
  #=> 02-01-1884 to 03-01-1887
```

### highlighting

_Returns context of text match results_

Defaults:

- `hl=true`
- `hl_chars=100`
- `hl_fl=text`
- `hl_num=3`

__Disabling Highlighting__

If you wish to turn highlighting off:

`hl=false`

__Characters__

This sets the number of characters that will be returned around a highlight match

`hl_chars=number`

```
hl_chars=100
```

__Field List__

Highlights will always be returned for the `text` field, but if you are searching multiple fields, you may wish to see highlights on those fields, also. You do not need to send `text` when specifying additional fields.

`hl_fl=field1,field2,field3`

```
hl_fl=annotations
hl_fl=annotations,catherwords
```

__Number__

The number of highlights returned per field. If you set `hl_num=3` for `text` and `annotations` you could receive up to 6 highlights, 3 from each field.

`hl_num=number`

```
hl_num=1
hl_num=5
```

### sorting

_Specify the order of results_

Defaults:

When no sort or partial sort is supplied

- query present: sort by "relevancy" descending
- given term is "relevancy", no order provided: sort descending
- given term is not "relevancy", no order provided: sort ascending

You may pass multiple fields to be sorted.  The first one appearing in the URL parameters will take precedence over the other(s).

`sort[]=field|direction`

```
sort[]=date|desc&sort[]=title|asc
```

__Sorting facets__

Please refer to the section on [facets](#facets) for information about how to sort facets, specifically.

### start and rows

_Manual pagination of results_

Defaults:

- start=0
- num=50

Note: Zero indexed

`start=number`<br>
`num=number`

```
start=0&num=50   # returns first 50 results
start=49&num=50  # returns second 50 results
start=9&num=10   # returns second 10 results
```

### text search

Please refer to [the Elasticsearch query string syntax](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html#query-string-syntax) for a list of all possibilities for text searching.

__Basic search__

`q=word`

```
q=multiple words
q=word
```

__Multiple fields__

By default, this will search the "text" field, you can specify a different one to use or multiple fields. If adding fields, you will want to make sure that your [highlights](#highlighting) include fields beyond "text"

`q=field:word`<br>
`q=field:word AND otherfield:other`<br>
`q=field:word OR otherfield:other`

__Advanced search__

`q="phrase of words"`<br>
`q=wildcard*`<br>
`q=word OR other`<br>
`q=word AND other`<br>
`q=(word OR other) OR -nothanks`
