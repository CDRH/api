=begin
CDRH API

API to access all public Center for Digital Research in the Humanities resources

OpenAPI spec version: 0.1.0

Generated by: https://github.com/swagger-api/swagger-codegen.git

=end

class ItemController < ApplicationController

  @@count = ["hits", "total"]
  @@facets = ["aggregations"]
  @@item = ["hits", "hits", 0, "_source"]
  @@items = ["hits", "hits"]

  # whether request comes in as a pipe character or encoded pipe
  # make sure that it is being split correctly
  @@separator = /[|(%7C)]/

  def index
    # Expected parameters
    # q
    # f[]
    # facet[]
    # facet_sort
    # facet_num
    # hl
    # min  # TODO implement
    # num
    # sort[]
    # start

    start = params["start"].blank? ? START : params["start"]
    num = params["num"].blank? ? NUM : params["num"]
    req = {
      "aggs" => {},
      "from" => start,
      # always include highlights by default
      "highlight" => {
        "fields" => {
          "cdrh-text" => {
            "fragment_size" => 100, "number_of_fragments" => 3
          }
        }
      },
      "size" => num,
      "query" => {},
    }
    bool = {}

    # TEXT SEARCH Q
    if !params["q"].blank?
      # default to searching text field
      # but can search _all field if necessary
      if params["q"].include?("*")
        bool["must"] = { "wildcard" => { "cdrh-text" => params["q"] } }
      else
        bool["must"] = { "match" => { "cdrh-text" => params["q"] } }
      end
    else
      bool["must"] = { "match_all" => {} }
    end

    # FACETS[]
    if !params["facet"].blank? && params["facet"].class == Array
      aggs = prepare_facets
      req["aggs"] = aggs
    end

    # FILTER FIELDS F[]
    if !params["f"].blank?
      fields = params["f"]
      pairs = fields.map { |f| f.split(@@separator) }
      filter = []
      pairs.each do |pair|
        filter << { "term" => { pair[0] => pair[1] } }
      end
      bool["filter"] = filter
    end

    # HIGHLIGHT
    if !params["hl"].blank? && params["hl"] == "false"
      # remove highlighting from request if they don't want it
      req.delete("highlight")
    end

    # SORT
    req["sort"] = []
    sort_param = params["sort"].blank? ? [] : params["sort"]
    sort_param.each do |sort|
      term, dir = sort.split(@@separator)
      # default to ascending if nothing specified
      dir = (dir == "asc" || dir == "desc") ? dir : "asc"
      req["sort"] << { term => dir }
    end
    # add default _score after everything else
    req["sort"] << "_score"

    req["query"]["bool"] = bool

    # debug line:
    # puts "req: #{req}"
    body = post_search req
    # display error and do not continue
    return true if !body

    count = body.dig(*@@count)
    # strip out only the fields for the item response
    items = combine_items_highlights(body)
    facets = get_facets(body)

    render json: JSON.pretty_generate({
      "req" => { "query_string" => request.fullpath },
      "res" => {
        "facets" => facets,
        "code" => 200,
        "count" => count,
        "items" => items,
      }
    })
  end

  def show
    req = {
      "query" => {
        "ids" => {
          "values" => [params["id"]]
        }
      }
    }

    if params["shortname"]
      req["query"]["ids"]["type"] = params["shortname"]
    end

    body = post_search req
    return true if !body

    count = body.dig(*@@count)
    if count > 0
      item = body.dig(*@@item)
    else
      item = {}
    end
    render json: JSON.pretty_generate({
      "req" => {
        "query_string" => request.fullpath
      },
      "res" => {
        "code" => 200,
        "count" => count,
        "item" => item
      }
    })

  end

  private

  def combine_items_highlights body
    hits = body.dig(*@@items)
    if hits
      return hits.map do |hit|
        hit["_source"]["highlight"] = hit["highlight"]
        hit["_source"]
      end
    else
      return []
    end
  end

  def get_facets body
    facets = body.dig(*@@facets)
    if facets
      formatted = {}
      facets.each do |field, info|
        formatted[field] = {}
        info["buckets"].each do |b|
          key = b["key"]
          val = b["doc_count"]
          formatted[field][key] = val
        end
      end
      return formatted
    else
      return []
    end
  end

  def prepare_facets
    # FACET_SORT
    order = { "_count" => "desc" }
    if !params["facet_sort"].blank?
      type, dir = params["facet_sort"].split(@@separator)
      dir = (dir == "asc" || dir == "desc") ? dir : "desc"
      type = type == "term" ? "_term" : "_count"
      order = { type => dir }
    end

    # FACET_START
    # Note: facet pagination not available currently, use -1 for "all"
    size = NUM
    size = params["facet_num"].blank? ? NUM : params["facet_num"]

    aggs = {}
    params["facet"].each do |f|
      aggs[f] = {
        "terms" => {
          # TODO if dataset is large, can implement partitions?
          # "include" => {
          #   "partition" => 0,
          #   "num_partitions" => 10
          # },
          "field" => f,
          "order" => order,
          "size" => size
        }
      }
    end
    return aggs
  end

end
