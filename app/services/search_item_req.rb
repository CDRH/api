class SearchItemReq

  # whether request comes in as a pipe character or encoded pipe
  # make sure that it is being split correctly
  @@separator = /(?:\||%7C)/

  attr_accessor :params

  def initialize params
    @params = params
  end

  def build_request
    # pagination
    num = @params["num"].blank? ? NUM : @params["num"]
    start = @params["start"].blank? ? START : @params["start"]
    # highlighting
    hl_chars = @params["hl_chars"].blank? ? HL_CHARS : @params["hl_chars"]
    hl_num = @params["hl_num"].blank? ? HL_NUM : @params["hl_num"]

    req = {
      "aggs" => {},
      "from" => start,
      # always include highlights by default
      "highlight" => {
        "fields" => {
          "text" => {
            "fragment_size" => hl_chars, "number_of_fragments" => hl_num
          }
        }
      },
      "size" => num,
      "query" => {},
    }
    bool = {}

    # TEXT SEARCH Q
    bool["must"] = text_search

    # FACETS[]
    if @params["facet"].present?
      aggs = facets
      req["aggs"] = aggs
    end

    # FILTER FIELDS F[]
    if @params["f"].present?
      bool["filter"] = filters
    end

    # HIGHLIGHT
    if @params["hl"].present? && @params["hl"] == "false"
      # remove highlighting from request if they don't want it
      req.delete("highlight")
    end

    # SORT
    req["sort"] = sort

    # add bool to request body
    req["query"]["bool"] = bool
    return req
  end

  def facets
    # FACET_SORT
    # by default also sort count desc
    type = "_count"
    dir = "desc"
    if @params["facet_sort"].present?
      type, dir = @params["facet_sort"].split(@@separator)
      dir = (dir == "asc" || dir == "desc") ? dir : "desc"
      type = type == "term" ? "_term" : "_count"
    end

    # FACET_START
    size = NUM
    size = @params["facet_num"].blank? ? NUM : @params["facet_num"]

    aggs = {}
    arrayifier(@params["facet"]).each do |f|
      # histograms use a different ordering terminology than normal aggs
      f_type = type == "_term" ? "_key" : "_count"

      if f.include?("date") || f.include?("_d")
        # NOTE: if nested fields will ever have dates we will
        # need to refactor this to be available to both
        if f.include?(".")
          field, interval = f.split(".")
        else
          field = f
          interval = "day"
        end
        formatted = interval == "year" ? "yyyy" : "yyyy-MM-dd"
        histogram = {
          "date_histogram" => {
            "field" => field,
            "interval" => interval,
            "format" => formatted,
            "min_doc_count" => 1,
            "order" => { f_type => dir },
          }
        }
        aggs[f] = histogram
      # if nested, has extra syntax
      elsif f.include?(".")
        path = f.split(".").first
        aggs[f] = {
          "nested" => {
            "path" => path
          },
          "aggs" => {
            "name" => {
              "terms" => {
                "field" => f,
                "order" => { type => dir },
                "size" => size
              }
            }
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
            "order" => { type => dir },
            "size" => size
          }
        }
      end
    end
    return aggs
  end

  def filters
    filter_list = []
    fields = arrayifier @params["f"]
    filters = fields.map {|f| f.split(@@separator, 2) }
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
      elsif filter[0].include?("date") || filter[0].include?("_d")
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

  # if non-array, return as single element array
  def arrayifier input
    if input.class != Array
      return [input]
    else
      return input
    end
  end

  def sort
    sort_obj = []
    sort_param = @params["sort"].blank? ? [] : arrayifier(@params["sort"])
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

  def text_search
    must = {}
    if @params["q"].present?
      # default to searching text field
      # but can search _all field if necessary
      must = {
        "query_string" => {
          "default_field" => "text",
          "query" => @params["q"]
        }
      }
      if @params["qfield"].present?
        must["query_string"]["fields"] = arrayifier @params["qfield"]
      end
    else
      must = { "match_all" => {} }
    end
    return must
  end

end
