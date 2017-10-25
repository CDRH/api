class SearchItemReq

  # whether request comes in as a pipe character or encoded pipe
  # make sure that it is being split correctly
  @@filter_separator = Regexp.new(SETTINGS["filter_separator"])
  @@fl_separator = Regexp.new(SETTINGS["fl_separator"])

  attr_accessor :params

  def initialize params
    @params = params
  end

  def build_request
    # pagination
    num = @params["num"].blank? ? SETTINGS["num"] : @params["num"]
    start = @params["start"].blank? ? SETTINGS["start"] : @params["start"]

    req = {
      "aggs" => {},
      "from" => start,
      "highlight" => {},
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
    req["highlight"] = highlights

    # SORT
    req["sort"] = sort

    if @params["fl"].present?
      req["_source"] = source
    end

    # add bool to request body
    req["query"]["bool"] = bool
    return req
  end

  def self.escape_chars(query)
    # many thanks to https://gist.github.com/bcoe/6505434
    # for the lucene escaping code below
    # Note: removed () and : from list, because escaping
    # those characters interfered with elasticsearch multifield searching
    escaped_characters = Regexp.escape('\\+-&|!{}[]^~*?\/')
    query.gsub(/([#{escaped_characters}])/, '\\\\\1')
  end

  def facets
    # FACET_SORT
    # unless specifically opting for "term", default to _count
    type = "_count"
    dir = "desc"
    if @params["facet_sort"].present?
      sort_type, sort_dir = @params["facet_sort"].split(@@filter_separator)
      type = "_term" if sort_type == "term"
      dir = sort_dir if sort_dir == "asc"
    end

    # FACET_SETTINGS["start"]
    size = SETTINGS["num"]
    size = @params["facet_num"].blank? ? SETTINGS["num"] : @params["facet_num"]

    aggs = {}
    Array.wrap(@params["facet"]).each do |f|
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
        aggs[f] = {
          "date_histogram" => {
            "field" => field,
            "interval" => interval,
            "format" => formatted,
            "min_doc_count" => 1,
            "order" => { f_type => dir },
          }
        }
      # if nested, has extra syntax
      elsif f.include?(".")
        path = f.split(".").first
        aggs[f] = {
          "nested" => {
            "path" => path
          },
          "aggs" => {
            f => {
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
    fields = Array.wrap(@params["f"])
    # each filter should be length 3 for field, type 1, type 2
    # (type 2 will only be used for dates)
    filters = fields.map {|f| f.split(@@filter_separator, 3) }
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

  def highlights
    hl = {}
    hl_chars = @params["hl_chars"].blank? ? SETTINGS["hl_chars"] : @params["hl_chars"]
    hl_num = @params["hl_num"].blank? ? SETTINGS["hl_num"] : @params["hl_num"]

    if @params["hl"] != "false"
      # include "text" highlighting by default
      hl["fields"] = {
        "text" => { "fragment_size" => hl_chars, "number_of_fragments" => hl_num }
      }
      if @params["hl_fl"].present?
        @params["hl_fl"].split(@@fl_separator).each do |field|
          hl["fields"][field] = {
            "fragment_size" => hl_chars,
            "number_of_fragments" => hl_num
          }
        end
      end
    end
    return hl
  end

  def sort
    sort_obj = []
    sort_param = nil
    if @params["sort"].blank?
      if @params["q"].present?
        sort_param = ["_score|desc"]
      else
        sort_param = [SETTINGS["sort_fl"]]
      end
    else
      sort_param = Array.wrap(@params["sort"])
    end

    sort_param.each do |sort|
      term, dir = sort.split(@@filter_separator)
      term = "_score" if term == "relevancy"
      if dir.blank?
        dir = term == "relevancy" ? "desc" : "asc"
      end
      sort_obj << { term => dir }
    end

    return sort_obj
  end

  def source
    all = @params["fl"].split(@@fl_separator)
    blist, wlist = all.partition { |f| f.start_with?("!") }
    blist.map! { |f| f[1..-1] }
    criteria = {}
    criteria["includes"] = wlist if !wlist.empty?
    criteria["excludes"] = blist if !blist.empty?
    return criteria
  end

  def text_search
    must = {}
    if @params["q"].present?
      query = SearchItemReq.escape_chars(@params["q"])
      # default to searching text field
      # but can search _all field if necessary
      must = {
        "query_string" => {
          "query" => query
        }
      }
      # attempt to detect if the query passed in is searching specific fields
      # assuming that text fields contain word "text" or "_t" in title
      # if no field specified, use "text" as default field
      text_field_regex = /^\(?[a-zA-Z0-9_]*(?:text|_t)[a-zA-Z0-9_]*:./
      if @params["q"][text_field_regex].nil?
        must["query_string"]["default_field"] = "text"
      end
    else
      must = { "match_all" => {} }
    end
    return must
  end

end
