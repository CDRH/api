=begin
CDRH API

API to access all public Center for Digital Research in the Humanities resources

OpenAPI spec version: 0.1.0

Generated by: https://github.com/swagger-api/swagger-codegen.git

=end

class DefaultController < ApplicationController

  def root
    render json: JSON.pretty_generate({
      "res" => {
        "code" => 200
      },
      "info" => {
        "api_updated" => CONFIG["api_updated"],
        "contact" => CONFIG["cdrh@unl.edu"],
        "description" => CONFIG["description"],
        "documentation" => CONFIG["documentation"],
        "index_updated" => "TODO",
        "license" => CONFIG["license"],
        "terms_of_service" => CONFIG["terms_of_service"],
        "version" => VERSION,
        # TODO should we be obtaining these from
        # Rails.application.routes or similar?
        "endpoints" => [
          "/",
          "/collection/{shortname}/info",
          "/collection/{shortname}/item/{id}",
          "/collections",
          "/item/{id}",
          "/items"
        ],
        # TODO get descriptions from ES mapping?
        # would rather not manually type in somewhere
        "fields" => {},
      }
    })
  end
end
