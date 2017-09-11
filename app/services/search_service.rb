require 'rest-client'

class SearchService

  attr_accessor :url, :params, :user_req

  def initialize url, params={}, user_req
    @url = url
    @params = params
    @user_req = user_req
  end

  def post url_ending, json
    res = RestClient.post("#{@url}/#{url_ending}", json.to_json, { "content-type" => "json" } )
    return JSON.parse(res.body)
  rescue => e
    return e
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
    if raw_res.class == RuntimeError
      on_error raw_res, req
    else
      res = build_collections_response raw_res
      on_success req, res
    end
  end

  def search_item id
    req = {
      "query" => {
        "ids" => {
          "values" => [params["id"]]
        }
      }
    }
    if @params["collection"].present?
      req["query"]["ids"]["type"] = @params["collection"]
    end
    raw_res = post "_search", req
    if raw_res.class == RuntimeError
      on_error raw_res, req
    else
      res = build_item_response raw_res
      on_success req, res
    end
  end

  def search_items
    req = build_item_request
    raw_res = post "_search", req
    if raw_res.class == RuntimeError
      on_error raw_res, req
    else
      res = build_item_response raw_res
      on_success req, res
    end
  end

  protected

  def on_error error_msg, req, friendly_msg="Something went wrong"
    {
      "req" => {
        "query_string" => @user_req,
        "query_obj" => req
      },
      "res" => {
        "code" => 500,
        "message" => friendly_msg,
        "info" => {
          "documentation" => "TODO",
          "error" => error_msg.inspect,
          "suggestion" => "TODO"
        }
      }
    }
  end

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
    SearchCollRes.new(res).build_response
  end

  def build_item_request
    SearchItemReq.new(@params).build_request
  end

  def build_item_response res
    SearchItemRes.new(res).build_response
  end

end
