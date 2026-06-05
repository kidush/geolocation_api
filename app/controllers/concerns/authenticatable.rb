module Authenticatable
  extend ActiveSupport::Concern

  BEARER_PATTERN = /\ABearer (.+)\z/

  included do
    before_action :authenticate!
  end

  private

  def authenticate!
    return if expected_token.blank?

    token = request.authorization.to_s[BEARER_PATTERN, 1]
    return if token.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected_token)

    response.set_header("WWW-Authenticate", 'Bearer realm="geolocation-api"')
    render_error(status: :unauthorized, title: "Unauthorized",
                 detail: "Missing or invalid bearer token")
  end

  def expected_token
    ENV["API_TOKEN"]
  end
end
