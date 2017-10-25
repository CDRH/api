require 'test_helper'

class SearchItemReqTest < ActiveSupport::TestCase

  def test_escape_chars

    # phrase search (quotation marks)
    query = '"fire in the fireplace"'
    assert_equal SearchItemReq.escape_chars(query), "\"fire in the fireplace\""

    # make sure that (text:searches) are not destroyed
    query = '(text:water) OR (annotations_text:Cather)'
    assert_equal SearchItemReq.escape_chars(query), "(text:water) OR (annotations_text:Cather)"

    # escape odd numbered quotation marks
    query = '"something'
    assert_equal SearchItemReq.escape_chars(query), "\"something"
    query = '"phrase" plus "'
    assert_equal SearchItemReq.escape_chars(query), "\"phrase\" plus \""

    # escape brackets, etc
    query = '{\\+~'
    assert_equal SearchItemReq.escape_chars(query), "\\{\\\\\\+\\~"

  end

  def test_facets

    # normal with no pagination overrides
    facets = SearchItemReq.new({ "facet" => [ "title" ] }).facets
    assert_equal facets, {"title"=>{"terms"=>{"field"=>"title", "order"=>{"_count"=>"desc"}, "size"=>20}}}

    # normal with pagination overrides, multiple facets
    facets = SearchItemReq.new({
      "facet_num" => 10,
      "facet_sort" => "term|asc",
      "facet" => [ "title", "subcategory" ]
    }).facets
    assert_equal facets, {"title"=>{"terms"=>{"field"=>"title", "order"=>{"_term"=>"asc"}, "size"=>10}}, "subcategory"=>{"terms"=>{"field"=>"subcategory", "order"=>{"_term"=>"asc"}, "size"=>10}}}

    # should be blank if there are no facets provided
    facets = SearchItemReq.new({
      "facet_num" => 1,
      "facet_sort" => "nonterm|asc",
      "facet" => []
    }).facets
    assert_equal facets, {}

    # getting dates involved
    facets = SearchItemReq.new({ "facet" => [ "date.year", "date"] }).facets
    assert_equal facets, {"date.year"=>{"date_histogram"=>{"field"=>"date", "interval"=>"year", "format"=>"yyyy", "min_doc_count"=>1, "order"=>{"_count"=>"desc"}}}, "date"=>{"date_histogram"=>{"field"=>"date", "interval"=>"day", "format"=>"yyyy-MM-dd", "min_doc_count"=>1, "order"=>{"_count"=>"desc"}}}}

    # nested field
    facets = SearchItemReq.new({
      "facet_sort" => "term|desc",
      "facet" => [ "creator.name" ]
    }).facets
    assert_equal facets, {"creator.name"=>{"nested"=>{"path"=>"creator"}, "aggs"=>{"creator.name"=>{"terms"=>{"field"=>"creator.name", "order"=>{"_term"=>"desc"}, "size"=>20}}}}}

    # with non-array
    facets = SearchItemReq.new({ "facet" => "title" }).facets
    assert_equal facets, {"title"=>{"terms"=>{"field"=>"title", "order"=>{"_count"=>"desc"}, "size"=>20}}}

    # sort term order specified
    facets = SearchItemReq.new({ "facet" => ["title", "format"], "facet_sort" => "term|desc" }).facets
    assert_equal facets, {"title"=>{"terms"=>{"field"=>"title", "order"=>{"_term"=>"desc"}, "size"=>20}}, "format"=>{"terms"=>{"field"=>"format", "order"=>{"_term"=>"desc"}, "size"=>20}}}

    # sort term no order specified
    facets = SearchItemReq.new({ "facet" => ["title", "format"], "facet_sort" => "term" }).facets
    assert_equal facets, {"title"=>{"terms"=>{"field"=>"title", "order"=>{"_term"=>"desc"}, "size"=>20}}, "format"=>{"terms"=>{"field"=>"format", "order"=>{"_term"=>"desc"}, "size"=>20}}}

    # sort count, no order specified
    facets = SearchItemReq.new({ "facet" => ["title"], "facet_sort" => "count" }).facets
    assert_equal facets, {"title"=>{"terms"=>{"field"=>"title", "order"=>{"_count"=>"desc"}, "size"=>20}}}

  end

  def test_filters

    # single filter
    filters = SearchItemReq.new({ "f" => ["category|Writings"] }).filters
    assert_equal filters, [{"term"=>{"category"=>"Writings"}}]

    # multiple filters
    filters = SearchItemReq.new({ "f" => ["category|Writings", "author.name|Herriot, James"] }).filters
    assert_equal filters, [{"term"=>{"category"=>"Writings"}}, {"nested"=>{"path"=>"author", "query"=>{"term"=>{"author.name"=>"Herriot, James"}}}}]

    # single year
    filters = SearchItemReq.new({ "f" => ["date|1900"] }).filters
    assert_equal filters, [{"range"=>{"date"=>{"gte"=>"1900-01-01", "lte"=>"1900-12-31", "format"=>"yyyy-MM-dd"}}}]

    # double year
    filters = SearchItemReq.new({ "f" => ["date|1900|1904"] }).filters
    assert_equal filters, [{"range"=>{"date"=>{"gte"=>"1900-01-01", "lte"=>"1904-12-31", "format"=>"yyyy-MM-dd"}}}]

    # double day range
    filters = SearchItemReq.new({ "f" => ["date|1904-01-03|1908-12-10"] }).filters
    assert_equal filters, [{"range"=>{"date"=>{"gte"=>"1904-01-03", "lte"=>"1908-12-10", "format"=>"yyyy-MM-dd"}}}]

    # nested field
    filters = SearchItemReq.new({ "f" => ["creator.name|Willa, Cather"] }).filters
    assert_equal filters, [{"nested"=>{"path"=>"creator", "query"=>{"term"=>{"creator.name"=>"Willa, Cather"}}}}]

    # dynamic field
    filters = SearchItemReq.new({ "f" => ["publication_d|1900"] }).filters
    assert_equal filters, [{"range"=>{"publication_d"=>{"gte"=>"1900-01-01", "lte"=>"1900-12-31", "format"=>"yyyy-MM-dd"}}}]

    # with non-array
    filters = SearchItemReq.new({ "f" => "category|Writings" }).filters
    assert_equal filters, [{"term"=>{"category"=>"Writings"}}]

    # where empty
    filters = SearchItemReq.new({ "f" => "places|" }).filters
    assert_equal filters, ["term"=>{"places"=>""}]

  end

  def test_highlights

    # no parameters
    hl = SearchItemReq.new({}).highlights
    assert_equal hl, {"fields"=>{"text"=>{"fragment_size"=>100, "number_of_fragments"=>3}}}

    # specifying fragment size and number
    hl = SearchItemReq.new({ "hl_chars" => 20, "hl_num" => 1 }).highlights
    assert_equal hl, {"fields"=>{"text"=>{"fragment_size"=>20, "number_of_fragments"=>1}}}

    # fragment size and number multiple fields
    hl = SearchItemReq.new({ "hl_chars" => 20, "hl_num" => 1, "hl_fl" => "annotations,extra" }).highlights
    assert_equal hl, {"fields"=>{"text"=>{"fragment_size"=>20, "number_of_fragments"=>1}, "annotations"=>{"fragment_size"=>20, "number_of_fragments"=>1}, "extra"=>{"fragment_size"=>20, "number_of_fragments"=>1}}}

    # no highlights despite params
    hl = SearchItemReq.new({ "hl_fl" => "annotations", "hl" => "false" }).highlights
    assert_equal hl, {}

    # highlight field list
    hl = SearchItemReq.new({ "hl_fl" => "annotations, text" }).highlights
    assert_equal hl, {"fields"=>{"text"=>{"fragment_size"=>100, "number_of_fragments"=>3}, "annotations"=>{"fragment_size"=>100, "number_of_fragments"=>3}}}

  end

  def test_sort

    # single sort
    sort = SearchItemReq.new({ "sort" => ["title|asc"] }).sort
    assert_equal sort, [{"title"=>"asc"}]

    # multiple sorts and subfield
    sort = SearchItemReq.new({ "sort" => ["title|desc", "author.name|asc"] }).sort
    assert_equal sort, [{"title"=>"desc"}, {"author.name"=>"asc"}]

    # with non-array
    sort = SearchItemReq.new({ "sort" => "title|asc" }).sort
    assert_equal sort, [{"title"=>"asc"}]

    # no sort specified, query present
    sort = SearchItemReq.new({ "q" => "water" }).sort
    assert_equal sort, [{"_score"=>"desc"}]

    # no sort direction specified, query present
    sort = SearchItemReq.new({ "q" => "water", "sort" => "date" }).sort
    assert_equal sort, [{"date"=>"asc"}]

    # sort specified, query present
    sort = SearchItemReq.new({ "q" => "water", "sort" => "date|desc" }).sort
    assert_equal sort, [{"date"=>"desc"}]

    # no sort specified, no query
    sort = SearchItemReq.new({}).sort
    assert_equal sort, [{"identifier" => "asc"}]

    # no sort direction specified, no query
    sort = SearchItemReq.new({ "sort" => "title" }).sort
    assert_equal sort, [{"title" => "asc"}]
  end

  def test_text_search

    # simple
    text = SearchItemReq.new({ "q" => "water" }).text_search
    assert_equal text, {"query_string"=>{"default_field"=>"text", "query"=>"water"}}

    # boolean
    text = SearchItemReq.new({ "q" => "water AND college" }).text_search
    assert_equal text, {"query_string"=>{"default_field"=>"text", "query"=>"water AND college"}}

    # multiple fields
    text = SearchItemReq.new({ "q" => "(text:water) AND (annotations:water)" }).text_search
    assert_equal text, {"query_string"=>{"query"=>"(text:water) AND (annotations:water)"}}

    # multiple fields different input
    text = SearchItemReq.new({ "q" => "(text:water) OR (annotations:balcony)" }).text_search
    assert_equal text, {"query_string"=>{"query"=>"(text:water) OR (annotations:balcony)"}}

    # multiple fields with grouped inputs
    text = SearchItemReq.new({ "q" => '(text:water OR "fire in the fireplace") OR (annotations:water AND "fire in the fireplace")'}).text_search
    assert_equal text, {"query_string"=>{"query"=>"(text:water OR \"fire in the fireplace\") OR (annotations:water AND \"fire in the fireplace\")"}}

    # non-text field search
    text = SearchItemReq.new({ "q" => "transcriptions_t:wouldnt" }).text_search
    assert_equal text, {"query_string"=>{"query"=>"transcriptions_t:wouldnt"}}

    # text field search beginning with what looks like text field
    text = SearchItemReq.new({ "q" => "yosemite: cool place to visit" }).text_search
    assert_equal text, {"query_string"=>{"default_field"=>"text", "query"=>"yosemite: cool place to visit"}}

    # text field search beginning with what really looks like a text field
    text = SearchItemReq.new({ "q" => "Exploring the Text: Cather's Hand" }).text_search
    assert_equal text, {"query_string"=>{"default_field"=>"text", "query"=>"Exploring the Text: Cather's Hand"}}

    # none
    text = SearchItemReq.new({}).text_search
    assert_equal text, { "match_all" => {} }

  end

  def test_source

    # spaces, whitelist only
    source = SearchItemReq.new({ "fl" => "title, creator.name" }).source
    assert_equal source, {"includes"=>["title", "creator.name"]}

    # blacklist only
    source = SearchItemReq.new({ "fl" => "!title,!creator.name" }).source
    assert_equal source, {"excludes"=>["title", "creator.name"]}

    # both
    source = SearchItemReq.new({ "fl" => "id, title, date, !dat*" }).source
    assert_equal source, {"includes"=>["id", "title", "date"], "excludes"=>["dat*"]}

  end

end
