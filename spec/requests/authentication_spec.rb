require "rails_helper"

RSpec.describe "Authentication", type: :request do
  def response_json
    JSON.parse(response.body)
  end

  context "when API_TOKEN is configured" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("API_TOKEN").and_return("secret-token")
    end

    it "allows requests with a valid bearer token" do
      get "/geolocations", headers: { "Authorization" => "Bearer secret-token" }

      expect(response).to have_http_status(:ok)
    end

    it "rejects requests without an Authorization header" do
      get "/geolocations"

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to include("Bearer")
      expect(response_json["errors"].first["title"]).to eq("Unauthorized")
    end

    it "rejects requests with a wrong token" do
      get "/geolocations", headers: { "Authorization" => "Bearer wrong-token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects non-bearer authorization schemes" do
      get "/geolocations", headers: { "Authorization" => "Basic c2VjcmV0" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "protects create" do
      post "/geolocations", params: { ip: "8.8.8.8" }.to_json,
                            headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      expect(Geolocation.count).to eq(0)
    end

    it "protects destroy" do
      create(:geolocation, ip: "8.8.8.8")

      delete "/geolocations", params: { ip: "8.8.8.8" }

      expect(response).to have_http_status(:unauthorized)
      expect(Geolocation.count).to eq(1)
    end

    it "keeps the health check endpoint public" do
      get "/up"

      expect(response).to have_http_status(:ok)
    end
  end

  context "when API_TOKEN is not configured" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("API_TOKEN").and_return(nil)
    end

    it "allows requests without a token" do
      get "/geolocations"

      expect(response).to have_http_status(:ok)
    end
  end
end
