require 'rest-client'

class ApplicationController < ActionController::API

  def post_search(json, error_method=method(:display_error))
    auth_hash = { "Authorization" => "Basic #{Base64::encode64("#{ES_USER}:#{ES_PASSWORD}")}" }
    res = RestClient.post("#{ES_URI}/_search", json.to_json, auth_hash.merge({ "content-type" => "json" }))
    raise
    return JSON.parse(res.body)
  rescue => e
    error_method.call(e, json)
    return nil
  end

  # I am so pleased that this works
  # as a default error handler
  def display_error(error, req_body)
    render(status: 500, json: JSON.pretty_generate({
      "res" => {
        "code" => 500,
        "api_version" => Api::Application::VERSION,
        "message" => "TODO",
        "info" => {
          "documentation" => "TODO",
          "error" => error.inspect,
          "suggestion" => "TODO"
        }
      },
      "req" => {
        "query_string" => request.fullpath,
        "query_obj" => req_body
      }
    })) and return
  end

end
