require "rails_helper"

RSpec.describe "Unknown routes", type: :request do
  def response_json
    JSON.parse(response.body)
  end

  it "returns a JSON:API 404 for an unknown path" do
    get "/nonsense"

    expect(response).to have_http_status(:not_found)
    expect(response.content_type).to include("application/vnd.api+json")
    expect(response_json["errors"].first["detail"]).to include("/nonsense")
  end

  it "returns a JSON:API 404 for unknown paths with other verbs" do
    post "/geolocations/42/bogus"

    expect(response).to have_http_status(:not_found)
    expect(response_json["errors"]).to be_present
  end

  it "does not require authentication" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("API_TOKEN").and_return("secret-token")

    get "/nonsense"

    expect(response).to have_http_status(:not_found)
  end
end
