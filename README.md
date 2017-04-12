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

Standard keyword fields

`facet[]=keyword_field`

```
facet[]=category
facet[]=category&facet[]=title
```

Nested fields

`facet[]=nested_field.keyword_field`

```
facet[]=creator.name
facet[]=creator.name&facet[]=creator.role
```

Date ranges (currently supports days or years)

`facet[]=date_field.range`

```
facet[]=date.year
  #=> { 1889 : 10, 1890 : 20 }

facet[]=date
  #=> { 01-02-1889 : 2, 03-04-1889 : 8 }
```

### field list

Restrict the fields displayed per document in the response. Use `!` to exclude a field. Wildcards in fieldnames supported.

`fl=yes,!no`

```
fl=title,!date*,date_written
```

### filters

Standard keyword field

`f[]=field|type`

```
f[]=category|Writings
f[]=category|Writings&f[]=format|manuscript
```

Nested fields

`f[]=nested.keyword|type`

```
f[]=creator.name|Cather, Willa
f[]=contributor.role|Editor
```

Date field

If given one date, will use it has both start and end.

Can give year range or specify date range

`f[]=field|range_start|(range_end)`

```
f[]=date|1884
  #=> 01-01-1884 to 12-31-1884
f[]=date|1884|1887
  #=> 01-01-1884 to 12-31-1887

f[]=date|1884-02-01|1887-03-01
  #=> 02-01-1884 to 03-01-1887
```

### highlighting

If you wish to turn highlighting off:

```
hl=false
```

If highlighting is on, it is set by default to return 3 occasions of a word match set among the 100 surrounding characters.  Change this with `hl_num` and `hl_chars`, respectively.

Changing the characters which appear around the highlighted word:

`hl_chars=number`  
`hl_num=number`

```
hl_chars=30&hl_num=10
```

### sorting

Document results:

`sort[]=field|direction`

```
sort[]=date|desc&sort[]=title|asc
```

Facet results:

Always defaults to score (_count) and descending, so unnecessary to add unless overriding default

`facet_sort=field|direction`

```
facet_sort=term|desc
facet_sort=anything_not_term|asc
```

### start and rows

Note: Zero indexed

`start=number`  
`num=number`

```
start=0&num=50   # returns first 50 results
start=9&num=10   # returns second 10 results
```

### text search

Please refer to [the Elasticsearch query string syntax](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html#query-string-syntax) for a list of all possibilities for text searching.

#### Basic Search

`q=word`

```
q=multiple words
q=word
```

#### Multiple Fields

By default, this will search the "text" field, you can specify a different one to use or multiple fields

- `q=field:word`
- `q=field:word&otherfield:other`

#### Advanced Search

`q="phrase of words"`  
`q=wildcard*`  
`q=word OR other`  
`q=word AND other`  
`q=(word OR other) OR -nothanks`
