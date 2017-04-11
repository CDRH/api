require 'test_helper'

class SearchItemReqTest < ActiveSupport::TestCase

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
    assert_equal facets, {"creator.name"=>{"nested"=>{"path"=>"creator"}, "aggs"=>{"name"=>{"terms"=>{"field"=>"creator.name", "order"=>{"_term"=>"desc"}, "size"=>20}}}}}

    # with non-array
    facets = SearchItemReq.new({ "facet" => "title" }).facets
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

  end

  def test_sort

    # single sort
    sort = SearchItemReq.new({ "sort" => ["title|asc"] }).sort
    assert_equal sort, [{"title"=>"asc"}, "_score"]

    # multiple sorts
    sort = SearchItemReq.new({ "sort" => ["title|desc", "author.name|asc"] }).sort
    assert_equal sort, [{"title"=>"desc"}, {"author.name"=>"asc"}, "_score"]

    # with non-array
    sort = SearchItemReq.new({ "sort" => "title|asc" }).sort
    assert_equal sort, [{"title"=>"asc"}, "_score"]

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
    assert_equal text, {"query_string"=>{"default_field"=>"text", "query"=>"(text:water) AND (annotations:water)"}}

    # none
    text = SearchItemReq.new({}).text_search
    assert_equal text, { "match_all" => {} }

  end

end
