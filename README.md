# api
API to access all public Center for Digital Research in the Humanities resources

## item query

### facets

Standard keyword fields

```
facet[]=keyword_field

facet[]=category
facet[]=category&facet[]=title
```

Nested fields

```
facet[]=nested_field.keyword_field

facet[]=creator.name
facet[]=creator.name&facet[]=creator.role
```

Date ranges (currently supports days or years)

```
facet[]=date_field.range

facet[]=date.year
  #=> { 1889 : 10, 1890 : 20 }

facet[]=date
  #=> { 01-02-1889 : 2, 03-04-1889 : 8 }
```

### filter fields

Standard keyword field

```
f[]=field|type

f[]=category|Writings
f[]=category|Writings&f[]=format|manuscript
```

Nested fields

```
f[]=nested.keyword|type

f[]=creator.name|Cather, Willa
f[]=contributor.role|Editor
```

Date field

If given one date, will use it has both start and end.

Can give year range or specify date range

```
f[]=field|range_start|(range_end)

f[]=date|1884
  #=> 01-01-1884 to 12-31-1884
f[]=date|1884|1887
  #=> 01-01-1884 to 12-31-1887

f[]=date|1884-02-01|1887-03-01
  #=> 02-01-1884 to 03-01-1887
```

### highlighting

Highlighting is turned on by default with `fragment_size` of 100, `number_of_fragments` of 3.

If you wish to turn highlighting off:

```
hl=false
```

**Proposal:  Add parameter to adjust size and number of highlight fragments**

### sort

Document results:

```
sort[]=field|direction

sort[]=date|desc&sort[]=title|asc
```

Facet results:

Always defaults to score (_count) and descending, so unnecessary to add unless overriding default

```
facet_sort=field|direction

facet_sort=term|desc
facet_sort=anything_not_term|asc
```

### start and rows

Note: Zero indexed

```
start=number
num=number

start=0&num=50   # returns first 50 results
start=9&num=10   # returns second 10 results
```

### text search

```
q=word

q=phrase search
q=word OR phrase search
q=wor*
```

**Proposal:  Create `qfield[]` to specify the text field(s) which should be searched**
