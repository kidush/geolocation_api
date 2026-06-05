class ApplicationController < ActionController::API
  JSONAPI_CONTENT_TYPE = "application/vnd.api+json".freeze

  include ErrorHandler

  private

  def render_jsonapi(record, status: :ok)
    render json: GeolocationSerializer.new(record).serializable_hash,
           status: status, content_type: JSONAPI_CONTENT_TYPE
  end
end
