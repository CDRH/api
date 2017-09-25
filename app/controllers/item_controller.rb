class ItemController < ApplicationController


  def index
    if params["collection"].present?
      params["f"] = [] if params["f"].blank?
      params["f"] << "collection|#{params["collection"]}"
    end
    res = SearchService.new(SETTINGS["es_uri"], params, request.fullpath)
      .search_items
    code = res.dig("res", "code")
    render status: code, json: JSON.pretty_generate(res)
  end

  def show
    res = SearchService.new(SETTINGS["es_uri"], params, request.fullpath)
      .search_item(params["id"])
    code = res.dig("res", "code")
    render status: code, json: JSON.pretty_generate(res)
  end

end
