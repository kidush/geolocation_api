module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :render_internal_error
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_parse_error
    rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from Geolocations::BadRequestError, with: :render_bad_request
    rescue_from Geolocations::InvalidInputError, with: :render_invalid_input
    rescue_from Geolocations::DuplicateError, with: :render_duplicate
    rescue_from Providers::Error, with: :render_provider_error
  end

  private

  def render_error(status:, title:, detail:)
    status_code = Rack::Utils.status_code(status)
    render json: { errors: [ { status: status_code.to_s, title: title, detail: detail } ] },
           status: status, content_type: ApplicationController::JSONAPI_CONTENT_TYPE
  end

  def render_parse_error(_exception)
    render_error(status: :bad_request, title: "Bad Request",
                 detail: "Request body is not valid JSON")
  end

  def render_parameter_missing(exception)
    render_error(status: :bad_request, title: "Bad Request", detail: exception.message)
  end

  def render_bad_request(exception)
    render_error(status: :bad_request, title: "Bad Request", detail: exception.message)
  end

  def render_not_found(exception)
    render_error(status: :not_found, title: "Not Found", detail: exception.message)
  end

  def render_invalid_input(exception)
    render_error(status: :unprocessable_content, title: "Invalid Input",
                 detail: exception.message)
  end

  def render_duplicate(exception)
    render_error(status: :conflict, title: "Conflict", detail: exception.message)
  end

  def render_provider_error(exception)
    Rails.logger.error("Geolocation provider error: #{exception.class}: #{exception.message}")
    render_error(status: :bad_gateway, title: "Provider Error",
                 detail: "The geolocation provider could not fulfill the request: #{exception.message}")
  end

  def render_internal_error(exception)
    Rails.logger.error("Unhandled error: #{exception.class}: #{exception.message}\n#{exception.backtrace&.first(10)&.join("\n")}")
    render_error(status: :internal_server_error, title: "Internal Server Error",
                 detail: "An unexpected error occurred")
  end
end
