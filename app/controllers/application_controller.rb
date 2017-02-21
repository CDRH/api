require 'rest-client'

class ApplicationController < ActionController::API

  def post_search json, error_method=method(:display_error)
    res = RestClient.post("#{ES_URI}/_search", json.to_json, { "content-type" => "json" })
    return JSON.parse(res.body)
  rescue => e
    error_method.call(e)
    return nil
  end

  # I am so pleased that this works
  # as a default error handler
  def display_error error
    render json: JSON.pretty_generate({
      "req" => {
        "query_string" => request.fullpath
      },
      "res" => {
        "code" => 500,
        "message" => "TODO",
        "info" => {
          "documentation" => "TODO",
          "error" => error.inspect,
          "suggestion" => "TODO"
        }
      }
    })
  end

end
