class SearchItemRes

  attr_reader :body, :debug

  @@count = ["hits", "total"]
  @@facets = ["aggregations"]
  @@facets_label = ["top_matches", "hits", "hits", "_source"]
  @@item = ["hits", "hits", 0, "_source"]
  @@items = ["hits", "hits"]

  def initialize(res, debug=false)
    @body = res
    @debug = debug
  end

  def build_response
    count = @body.dig(*@@count)
    # strip out only the fields for the item response
    items = combine_highlights
    facets = reformat_facets

    {
      "code" => 200,
      "count" => count,
      "api_version" => Api::Application::VERSION,
      "facets" => facets,
      "items" => items,
    }
  end

  def combine_highlights
    hits = @body.dig(*@@items)
    if hits
      hits.map do |hit|
        hit["_source"]["highlight"] = hit["highlight"] || {}
        hit["_source"]
      end
    else
      []
    end
  end

  def format_bucket_value(facets, field, bucket)
    # dates return in wonktastic ways, so grab key_as_string instead of gibberish number
    # but otherwise just grab the key if key_as_string unavailable
    key = bucket.key?("key_as_string") ? bucket["key_as_string"] : bucket["key"]
    val = bucket["doc_count"]
    source = key
    # top_matches is a top_hits aggregation which returns a list of terms
    # which were used for the facet.
    #   Example: "Willa Cather" and "WILLA CATHER"
    # Those terms will both have been normalized as "willa cather" but
    # we will want to display one of the non-normalized terms instead
    matches = bucket.dig("top_matches", "hits", "hits")
    if matches
      # elasticsearch stores nested source results without the "path"
      nested_child = field.split(".").last
      source = matches.first.dig("_source", nested_child)
    end
    facets[field][key] = {
      "num" => val,
      "source" => source
    }
  end

  def reformat_facets
    raw_facets = @body.dig(*@@facets)
    if raw_facets
      facets = {}
      raw_facets.each do |field, info|
        facets[field] = {}
        # nested fields do not have buckets at this level of response structure
        buckets = info.key?("buckets") ? info["buckets"] : info.dig(field, "buckets")

        if buckets
          buckets.each { |b| format_bucket_value(facets, field, b) }
        else
          facets[field] = {}
        end
      end
      facets
    else
      {}
    end
  end

end
