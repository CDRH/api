require 'test_helper'
require_relative '../../app/services/search_item_req.rb'

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
  end

end
