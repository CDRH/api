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
  @@separator = /(?:\||%7C)/

  def index
    # Expected parameters
    # debug  # TODO implement
    # q
    # f[]
    # facet[]
    # facet_sort
    # facet_num
    # hl
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
          "text" => {
            "fragment_size" => 100, "number_of_fragments" => 3
          }
        }
      },
      "size" => num,
      "query" => {},
    }
    bool = {}

    # TEXT SEARCH Q
    bool["must"] = build_text_search

    # FACETS[]
    if params["facet"].present? && params["facet"].class == Array
      aggs = build_facets
      req["aggs"] = aggs
    end

    # FILTER FIELDS F[]
    if params["f"].present?
      bool["filter"] = build_filters
    end

    # HIGHLIGHT
    if params["hl"].present? && params["hl"] == "false"
      # remove highlighting from request if they don't want it
      req.delete("highlight")
    end

    # SORT
    req["sort"] = build_sort

    # add bool to request body
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

    # build user info about request
    if params["debug"].present?
      request_info = {
        "query_string" => request.fullpath,
        "query_obj" => req
      }
    else
      request_info = {}
    end

    render json: JSON.pretty_generate({
      "res" => {
        "facets" => facets,
        "code" => 200,
        "count" => count,
        "items" => items,
      },
      "req" => request_info
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

    if params["shortname"].present?
      req["query"]["ids"]["type"] = params["shortname"]
    end

    body = post_search req
    return true if !body

    count = body.dig(*@@count)
    # /item/id probably doesn't have highlights at this
    # point but it could include them in the feature
    # if we build onto the api's functionality
    items = combine_items_highlights(body)

    render json: JSON.pretty_generate({
      "req" => {
        "query_string" => request.fullpath
      },
      "res" => {
        "code" => 200,
        "count" => count,
        # return as array so that accessible in same
        # way as /items results
        "items" => items
      }
    })

  end

  private

  def build_facets
    # FACET_SORT
    order = { "_count" => "desc" }
    if params["facet_sort"].present?
      type, dir = params["facet_sort"].split(@@separator)
      dir = (dir == "asc" || dir == "desc") ? dir : "desc"
      type = type == "term" ? "_term" : "_count"
      order = { type => dir }
    end

    # FACET_START
    size = NUM
    size = params["facet_num"].blank? ? NUM : params["facet_num"]

    aggs = {}
    params["facet"].each do |f|
      # if nested, has extra syntax
      if f.include?(".")
        path = f.split(".").first
        aggs[f] = {
          "nested" => {
            "path" => path
          },
          "aggs" => {
            "name" => {
              "terms" => {
                "field" => f,
                "order" => order,
                "size" => size
              }
            }
          }
        }
      elsif f.include?("date")
        # NOTE: if nested fields will ever have dates we will
        # need to refactor this to be available to both
        if f.include?("|")
          field, interval = f.split("|")
        else
          field = f
          interval = "day"
        end
        formatted = interval == "year" ? "yyyy" : "yyyy-MM-dd"
        aggs[f] = {
          "date_histogram" => {
            "field" => field,
            "interval" => interval,
            "format" => formatted,
            "min_doc_count" => 1,
            "order" => order,
          }
        }
      else
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
    end
    return aggs
  end

  def build_filters
    filter_list = []
    fields = params["f"]
    filters = fields.map { |f| f.split(@@separator) }
    filters.each do |filter|
      # NESTED FIELD FILTER
      if filter[0].include?(".")
        path = filter[0].split(".").first
        # this is a nested field and must be treated differently
        nested = {
          "nested" => {
            "path" => path,
            "query" => {
              "term" => {
                filter[0] => filter[1]
              }
            }
          }
        }
        filter_list << nested
      # DATE FIELD FILTER
      elsif filter[0].include?("date")
        # TODO rethink how all of the below is functioning, it is terrible

        # NOTE: if nested fields contain date this will have to be changed
        # if there is not an end date specified, reuse start date

        # this could come in as date|1884|1899
        #   -- filter date field by year range 84 - 99
        # or date|1969-05-01|1987-02-28

        field = filter.shift

        # now the remaining elements in filter should be dates
        if filter.length == 1
          start = filter[0]
          stop = filter[0]
        elsif filter.length == 2
          start = filter[0]
          stop = filter[1]
        else
          # TODO how to raise error here but not render twice?
          # redirect to error action?
        end

        start = "#{start}-01-01" if start.length == 4
        stop = "#{stop}-12-31" if stop.length == 4

        range = {
          "range" => {
            field => {
              "gte" => start,
              "lte" => stop,
              "format" => "yyyy-MM-dd",
            }
          }
        }
        filter_list << range
      # TRADITIONAL FILTERS
      else
        filter_list << { "term" => { filter[0] => filter[1] } }
      end
    end
    return filter_list
  end

  def build_sort
    sort_obj = []
    sort_param = params["sort"].blank? ? [] : params["sort"]
    sort_param.each do |sort|
      term, dir = sort.split(@@separator)
      # default to ascending if nothing specified
      dir = (dir == "asc" || dir == "desc") ? dir : "asc"
      sort_obj << { term => dir }
    end
    # add default _score after everything else
    sort_obj << "_score"
    return sort_obj
  end

  def build_text_search
    must = {}
    if params["q"].present?
      # default to searching text field
      # but can search _all field if necessary

      # TODO look into whether query_string syntax is appropriate
      # for "advanced" or whether we should be toggling between several
      advanced_search = is_advanced_query? params["q"]
      if advanced_search
        must = {
          "query_string" => {
            "default_field" => "text",
            "query" => params["q"]
          }
        }
      else
        must = { "match" => { "text" => params["q"] } }
      end
    else
      must = { "match_all" => {} }
    end
    return must
  end

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
      return []
    end
  end

  def is_advanced_query? query
    if query.include?("AND") ||
      query.include?("OR") ||
      query.include?("*")
      return true
    else
      return false
    end
  end

end
