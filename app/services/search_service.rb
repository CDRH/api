require 'rest-client'

class SearchService

  attr_accessor :url, :params, :user_req

  def initialize url, params={}, user_req
    @url = url
    @params = params
    @user_req = user_req
  end

  def post url_ending, json, error_method=method(:display_error)
    res = RestClient.post("#{@url}/#{url_ending}", json.to_json, { "content-type" => "json" } )
    return JSON.parse(res.body)
  rescue => e
    error_method.call(e, json)
    return nil
  end

  def search_collections
    req = {
      "aggs" => {
        "collections" => {
          "terms" => {
            "field" => "_type",
            "size" => 200
          }
        }
      },
      "size" => 0
    }
    raw_res = post "_search", req
    res = build_collections_response raw_res
    on_success req, res
  end

  def search_item id
    req = {
      "query" => {
        "ids" => {
          "values" => [params["id"]]
        }
      }
    }
    if @params["shortname"].present?
      req["query"]["ids"]["type"] = @params["shortname"]
    end
    raw_res = post "_search", req
    res = build_item_response raw_res
    on_success req, res
  end

  def search_items
    req = build_item_request
    raw_res = post "_search", req
    res = build_item_response raw_res
    on_success req, res
  end

  protected

  def on_success req, res
    json = {
      "req" => {
        "query_string" => @user_req
      },
      "res" => res
    }
    if @params["debug"].present?
      json["req"]["query_obj"] = req
    end
    return json
  end

  def build_collections_response res
    SearchCollectionsResponseBuilder.new(res).build_response
  end

  def build_item_request
    SearchItemRequestBuilder.new(@params).build_request
  end

  def build_item_response res
    SearchItemResponseBuilder.new(res).build_response
  end

  def display_error error, req_body
    {
      "something" => "is very wrong #{error}"
    }
    # render(status: 500, json: JSON.pretty_generate({
    #   "res" => {
    #     "code" => 500,
    #     "message" => "TODO",
    #     "info" => {
    #       "documentation" => "TODO",
    #       "error" => error.inspect,
    #       "suggestion" => "TODO"
    #     }
    #   },
    #   "req" => {
    #     "query_string" => @user_req,
    #     "query_obj" => req_body
    #   }
    # }))
  end

end
