class CollectionController < ApplicationController

  def index
    res = SearchService.new(ES_URI, params, request.fullpath)
      .search_collections
    render json: JSON.pretty_generate(res)
  end

  def show
    # TODO finish this endpoint

    render json: JSON.pretty_generate({
      "req" => {
        "query_string" => request.fullpath
      },
      "res" => {
        "code" => 200,
        "info" => {
          "collection" => {},
          "endpoints" => [],
          "fields" => {}
        }
      }
    })
  end

end
