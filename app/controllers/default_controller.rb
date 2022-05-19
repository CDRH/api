=begin
CDRH API

API to access all public Center for Digital Research in the Humanities resources

OpenAPI spec version: 0.1.0

Generated by: https://github.com/swagger-api/swagger-codegen.git

=end

class DefaultController < ApplicationController

  def root
    json = JSON.pretty_generate({
      "req" => {
        "query_string" => request.fullpath
      },
      "res" => {
        "code" => 200,
        "info" => {
          "api_updated" => METADATA["api_updated"],
          "contact" => METADATA["cdrh@unl.edu"],
          "description" => METADATA["description"],
          "documentation" => METADATA["documentation"],
          "index_updated" => "TODO",
          "license" => METADATA["license"],
          "terms_of_service" => METADATA["terms_of_service"],
          # TODO should we be obtaining these from
          # Rails.application.routes or similar?
          "endpoints" => [
            "/",
            "/items",
            "/item/{id}",
            "/collections",
            "/collection/{collection}/info",
            "/collection/{collection}/item/{id}",
          ],
          # TODO get descriptions from ES mapping?
          # would rather not manually type in somewhere
          # or possibly by reading in the YML file for the
          # schema definitions, which would prevent project
          # specific fields from popping up in this result
          "fields" => {},
        }
      }
    })
    render json: json
  end
end
