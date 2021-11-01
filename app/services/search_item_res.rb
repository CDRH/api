class SearchItemRes
  attr_reader :body, :debug

  @@count = ["hits", "total"]
  @@facets = ["aggregations"]
  @@item = ["hits", "hits", 0, "_source"]
  @@items = ["hits", "hits"]

  def initialize(res, debug = false)
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
      "facets" => facets,
      "items" => items
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

  def reformat_facets
    facets = @body.dig(*@@facets)
    if facets
      formatted = {}
      facets.each do |field, info|
        formatted[field] = {}
        # nested fields do not have buckets
        # at this level in the response structure
        buckets = info.key?("buckets") ? info["buckets"] : info.dig(field, "buckets")
        if buckets
          buckets.each do |b|
            # dates return in wonktastic ways, so grab key_as_string instead of gibberish number
            # but otherwise just grab the key if key_as_string unavailable
            key = b.has_key?("key_as_string") ? b["key_as_string"] : b["key"]
            val = b["doc_count"]
            formatted[field][key] = val
          end
        else
          formatted[field] = {}
        end
      end
      formatted
    else
      {}
    end
  end
end
