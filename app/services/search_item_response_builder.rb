class SearchItemResponseBuilder

  attr_reader :body, :debug

  @@count = ["hits", "total"]
  @@facets = ["aggregations"]
  @@item = ["hits", "hits", 0, "_source"]
  @@items = ["hits", "hits"]

  def initialize res, debug=false
    @body = res
    @debug = debug
  end

  def build_response
    count = @body.dig(*@@count)
    # strip out only the fields for the item response
    items = combine_highlights
    facets = reformat_facets

    # build user info about request
    if @debug
      request_info = {
        "query_string" => request.fullpath,
        "query_obj" => req
      }
    else
      request_info = {}
    end

    return {
      "res" => {
        "facets" => facets,
        "code" => 200,
        "count" => count,
        "items" => items,
      },
      "req" => request_info
    }
  end

  def combine_highlights
    hits = @body.dig(*@@items)
    if hits
      return hits.map do |hit|
        hit["_source"]["highlight"] = hit["highlight"]
        hit["_source"]
      end
    else
      return []
    end
  end

  def reformat_facets
    facets = @body.dig(*@@facets)
    if facets
      formatted = {}
      facets.each do |field, info|
        formatted[field] = {}
        buckets = {}
        # nested fields do not have buckets
        # at this level in the response structure
        if info.has_key?("buckets")
          buckets = info["buckets"]
        else
          # get second half of field name
          nested_field = field.split(".").last
          buckets = info.dig(nested_field, "buckets")
        end
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
      return formatted
    else
      return {}
    end
  end

end
