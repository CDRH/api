class SearchCollRes

  @@collections = ["aggregations", "collections", "buckets"]

  def initialize res
    @body = res
  end

  def build_response
    route_paths = Rails.application.routes.url_helpers

    collections = @body.dig(*@@collections)
      collections = [] if !collections
      collections.map! do |coll|
        {
          "collection_name" => coll["key"],
          "description" => "TODO",
          "image_id" => "TODO",
          "uri" => "TODO",
          "shortname" => coll["key"],
          "item_count" => coll["doc_count"],
          "endpoint" => route_paths.collection_path(coll["key"])
        }
      end

      return {
        "code" => 200,
        "info" => {
          "collections" => collections
        }
      }
  end

end
