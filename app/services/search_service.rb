require 'rest-client'

class SearchService

  attr_accessor :url, :params, :user_req

  def initialize(url, params={}, user_req)
    @url = url
    @params = params
    @user_req = user_req
  end

  def search_collections
    req = {
      "aggs" => {
        "collections" => {
          "terms" => {
            "field" => "collection",
            "size" => 200
          }
        }
      },
      "size" => 0
    }
    search(req)
  end

  def search_item(id)
    req = {
      "query" => {
        "bool" => {
          "must" => [
            {
              "term" => { "identifier" => id }
            }
          ]
        }
      }
    }
    if @params["collection"].present?
      req["query"]["bool"]["must"] << { "term" => { "collection" => @params["collection"] } }
    end
    search(req)
  end

  def search_items
    req = build_item_request
    search(req)
  end

  protected

  def build_collections_response(res)
    SearchCollRes.new(res).build_response
  end

  def build_item_request
    SearchItemReq.new(@params).build_request
  end

  def build_item_response(res)
    SearchItemRes.new(res).build_response
  end

  def on_error(error_msg, req, friendly_msg="Search service error")
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
          "error" => error_msg,
          "suggestion" => "TODO"
        }
      }
    }
  end

  def on_success(req, res)
    json = {
      "req" => {
        "query_string" => @user_req
      },
      "res" => res
    }
    if @params["debug"].present?
      json["req"]["query_obj"] = req
    end
    json
  end

  def post(url_ending, json)
    # Add Basic Authentication header if credentials present
    if Rails.application.credentials.elasticsearch.present? &&
      Rails.application.credentials.elasticsearch[:user].present? &&
      Rails.application.credentials.elasticsearch[:password].present?
      auth_hash = {
        "Authorization" => "Basic " +
          Base64::encode64(
            Rails.application.credentials.elasticsearch[:user] +
            ":" + Rails.application.credentials.elasticsearch[:password]
          )
      }
      res = RestClient.post(
        @url + "/" + url_ending,
        json.to_json,
        auth_hash.merge({ "content-type" => "json" })
      )
    else
      res = RestClient.post(
        @url + "/" + url_ending,
        json.to_json,
        {"content-type" => "json"}
      )
    end
    res
  rescue => e
    e
  end

  def search(req)
    res = post("_search", req)
    if res.class == RuntimeError
      on_error(res.inspect, req,
               "There was an error communicating with the search service")
    elsif res.class == RestClient::Forbidden
      on_error(res.response, req,
               "Communication with the search service was denied (40x "\
               "Forbidden). Please try again soon.")
    elsif res.class == RestClient::BadRequest
      on_error(res.response, req,
               "Something went wrong with the request to the search service. "\
               "Check for a mix of smart and regular quotes in your search, "\
               "as the search service cannot handle this.")
    elsif res.class == RestClient::ExceptionWithResponse
      on_error(JSON.parse(res.response), req,
               "An error occurred while the search service tried to process "\
               "your request.")
    else
      res = build_item_response(JSON.parse(res.body))
      on_success(req, res)
    end
  end
end
