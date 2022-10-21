class SearchItemReq

  # whether request comes in as a pipe character or encoded pipe
  # make sure that it is being split correctly
  @@filter_separator = Regexp.new(SETTINGS["filter_separator"])
  @@fl_separator = Regexp.new(SETTINGS["fl_separator"])

  attr_accessor :params

  def initialize(params)
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
    # uncomment below line to log ES query for debugging
    # puts req.to_json()
    return req
  end

  def self.escape_chars(query)
    # many thanks to https://gist.github.com/bcoe/6505434
    # for the lucene escaping code below
    # Note: removed () and : from list, because escaping
    # those characters interfered with elasticsearch multifield searching
    # Also removed * and ? from the list because escaping those
    # characters meant queries with uncertainty couldn't be done
    escaped_characters = Regexp.escape('\\+-&|!{}[]^~\/')
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
      if f.include?("date") || f[/_d$/]
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
            "calendar_interval" => interval,
            "format" => formatted,
            "min_doc_count" => 1,
            "order" => { f_type => dir },
          }
        }
      #nested facet, matching on another nested facet
      
      elsif f.include?("[")
        # will be an array including the original, and an alternate aggregation name
      

        options = JSON.parse(f)
        original = options[0]
        agg_name = options[1]
        facet = original.split("[")[0]
        # may or may not be nested
        nested = facet.include?(".")
        if nested
          path = facet.split(".").first
        end
        condition = original[/(?<=\[).+?(?=\])/]
        subject = condition.split("#").first
        predicate = condition.split("#").last
        aggregation = {
            # common to nested and non-nested
            "filter" => {
              "term" => {
                subject => predicate
              }
            },
            "aggs" => {
              agg_name => {
                "terms" => {
                  "field" => facet,
                  "order" => { type => dir },
                  "size" => size
                },
                "aggs" => {
                  "field_to_item" => {
                    "reverse_nested" => {},
                    "aggs" => {
                      "top_matches" => {
                        "top_hits" => {
                          "_source" => {
                            "includes" => [ agg_name ]
                          },
                          "size" => 1
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        #interpolate above hash into nested query
        if nested
          aggs[agg_name] = {
            "nested" => {
              "path" => path
            },
            "aggs" => {
              agg_name => aggregation
            }
          }
        else
          #otherwise it is the whole query
          aggs[agg_name] = aggregation
        end
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
              },
              "aggs" => {
                "top_matches" => {
                  "top_hits" => {
                    "_source" => {
                      "includes" => [ f ]
                    },
                    "size" => 1
                  }
                }
              }
            }
          }
        }
      else
        aggs[f] = {
          "terms" => {
            "field" => f,
            "order" => { type => dir },
            "size" => size
          },
          "aggs" => {
            "top_matches" => {
              "top_hits" => {
                "_source" => {
                  "includes" => [ f ]
                },
                "size" => 1
              }
            }
          }
        }
      end
    end
    aggs
  end

  def filters
    filter_list = []
    fields = Array.wrap(@params["f"])
    # each filter should be length 3 for field, type 1, type 2
    # (type 2 will only be used for dates)
    filters = fields.map {|f| f.split(@@filter_separator, 3) }
    filters.each do |filter|
      # filter aggregation with nesting
      if filter[0].include?("[")
        original = filter[0]
        facet = original.split("[")[0]
        nested = facet.include?(".")
        if nested
          path = facet.split(".").first
        end
        condition = original[/(?<=\[).+?(?=\])/]
        subject = condition.split("#").first
        predicate = condition.split("#").last
        term_match = {
          # "person.name" => "oliver wendell holmes"
          # Remove CR's added by hidden input field values with returns
          facet => filter[1].gsub(/\r/, "")
        }
        term_filter = {
          subject => predicate
        }
        if nested
          query = {
            "nested" => {
              "path" => path,
              "query" => {
                "bool" => {
                  "must" => [
                    { "match" => term_filter },
                    { "match" => term_match }
                  ]
                }
              }
            }
          }
        end
        filter_list << query
      #ordinary nested facet
      elsif filter[0].include?(".")
        path = filter[0].split(".").first
        # this is a nested field and must be treated differently
        nested = {
          "nested" => {
            "path" => path,
            "query" => {
              "term" => {
                # Remove CR's added by hidden input field values with returns
                filter[0] => filter[1].gsub(/\r/, "")
              }
            }
          }
        }
        filter_list << nested
      # DATE FIELD FILTER
      elsif filter[0].include?("date") || filter[0][/_d$/]
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
        # Remove CR's added by hidden input field values with returns
        filter_list << { "term" => { filter[0] => filter[1].gsub(/\r/, "") } }
      end
    end
    filter_list
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
    hl
  end

  def sort
    sort_obj = []
    sort_param = nil
    if @params["sort"].blank?
      if @params["q"].present?
        sort_param = ["_score"]
      else
        sort_param = [SETTINGS["sort_fl"]]
      end
    else
      sort_param = Array.wrap(@params["sort"])
    end

    sort_param.each do |sort|
      term, dir = sort.split(@@filter_separator)
      if term == "relevancy" || term == "_score"
        sort_obj << "_score"
      else
        dir = "asc" if dir.blank?
        # instructions for multivalued field sorting
        # ex: desc [D], [A, F] -> [A, F], [D] because A is max from set
        mode = dir == "desc" ? "max" : "min"
        # default to sorting missing values last, this may
        # be added as a configurable parameter later
        missing = "_last"

        sort_setting = {
          term => {
            "order" => dir,
            "mode" => mode,
            "missing" => missing
          }
        }
        # nested fields require different sorting setup
        # note: does not support nested fields inside of nested fields
        if term.include?(".")
          path = term.split(".").first
          sort_setting[term]["nested"] = { "path" => path }
        end
        sort_obj << sort_setting
      end

    end

    sort_obj
  end

  def source
    all = @params["fl"].split(@@fl_separator)
    blist, wlist = all.partition { |f| f.start_with?("!") }
    blist.map! { |f| f[1..-1] }
    criteria = {}
    criteria["includes"] = wlist if !wlist.empty?
    criteria["excludes"] = blist if !blist.empty?
    criteria
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
    must
  end

end
