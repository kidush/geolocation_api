require "rails_helper"

RSpec.describe "Geolocations API", type: :request do
  let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }

  def response_json
    JSON.parse(response.body)
  end

  describe "POST /geolocations" do
    it "creates a geolocation from an IP" do
      post "/geolocations", params: { ip: "8.8.8.8" }.to_json, headers: json_headers

      expect(response).to have_http_status(:created)
      expect(response.content_type).to include("application/vnd.api+json")
      expect(response_json.dig("data", "type")).to eq("geolocation")
      expect(response_json.dig("data", "attributes", "ip")).to eq("8.8.8.8")
      expect(response_json.dig("data", "attributes", "country_code")).to eq("US")
    end

    it "creates a geolocation from a JSON:API envelope" do
      body = { data: { type: "geolocations", attributes: { ip: "1.1.1.1" } } }

      post "/geolocations", params: body.to_json, headers: json_headers

      expect(response).to have_http_status(:created)
      expect(response_json.dig("data", "attributes", "ip")).to eq("1.1.1.1")
    end

    it "creates a geolocation from a URL" do
      stub_dns("example.com", "93.184.216.34")

      post "/geolocations", params: { url: "https://example.com" }.to_json, headers: json_headers

      expect(response).to have_http_status(:created)
      expect(response_json.dig("data", "attributes", "ip")).to eq("93.184.216.34")
      expect(response_json.dig("data", "attributes", "url")).to eq("https://example.com")
    end

    it "returns 400 when neither ip nor url is given" do
      post "/geolocations", params: {}.to_json, headers: json_headers

      expect(response).to have_http_status(:bad_request)
      expect(response_json["errors"].first["detail"]).to match(/Provide either/)
    end

    it "returns 400 when both ip and url are given" do
      post "/geolocations", params: { ip: "8.8.8.8", url: "https://example.com" }.to_json,
                            headers: json_headers

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 for a malformed JSON body" do
      post "/geolocations", params: "{not json", headers: json_headers

      expect(response).to have_http_status(:bad_request)
      expect(response_json["errors"].first["detail"]).to match(/not valid JSON/)
    end

    it "returns 422 for an invalid IP" do
      post "/geolocations", params: { ip: "999.999.999.999" }.to_json, headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response_json["errors"].first["detail"]).to match(/not a valid IP/)
    end

    it "returns 422 for an unresolvable URL" do
      stub_dns_failure("nonexistent.invalid")

      post "/geolocations", params: { url: "https://nonexistent.invalid" }.to_json,
                            headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response_json["errors"].first["detail"]).to match(/Could not resolve/)
    end

    it "returns 409 for a duplicate IP" do
      create(:geolocation, ip: "8.8.8.8")

      post "/geolocations", params: { ip: "8.8.8.8" }.to_json, headers: json_headers

      expect(response).to have_http_status(:conflict)
      expect(response_json["errors"].first["detail"]).to match(/already stored/)
    end

    it "returns 502 when the provider is unavailable" do
      provider = instance_double(Providers::Base)
      allow(provider).to receive(:lookup)
        .and_raise(Providers::UnavailableError, "service down")
      allow(Providers).to receive(:current).and_return(provider)

      post "/geolocations", params: { ip: "8.8.8.8" }.to_json, headers: json_headers

      expect(response).to have_http_status(:bad_gateway)
      expect(response_json["errors"].first["title"]).to eq("Provider Error")
    end

    it "returns 502 when the provider rejects our credentials" do
      provider = instance_double(Providers::Base)
      allow(provider).to receive(:lookup)
        .and_raise(Providers::AuthenticationError, "invalid key")
      allow(Providers).to receive(:current).and_return(provider)

      post "/geolocations", params: { ip: "8.8.8.8" }.to_json, headers: json_headers

      expect(response).to have_http_status(:bad_gateway)
    end
  end

  describe "GET /geolocations" do
    it "lists all stored geolocations" do
      create_list(:geolocation, 3)

      get "/geolocations"

      expect(response).to have_http_status(:ok)
      expect(response_json["data"].size).to eq(3)
    end

    it "returns an empty list when nothing is stored" do
      get "/geolocations"

      expect(response).to have_http_status(:ok)
      expect(response_json["data"]).to eq([])
    end

    it "returns a single geolocation by ip" do
      create(:geolocation, ip: "8.8.8.8", city: "Mountain View")

      get "/geolocations", params: { ip: "8.8.8.8" }

      expect(response).to have_http_status(:ok)
      expect(response_json.dig("data", "attributes", "city")).to eq("Mountain View")
    end

    it "returns a single geolocation by url" do
      create(:geolocation, ip: "93.184.216.34", url: "https://example.com")

      get "/geolocations", params: { url: "https://example.com" }

      expect(response).to have_http_status(:ok)
      expect(response_json.dig("data", "attributes", "url")).to eq("https://example.com")
    end

    it "returns 404 for an unknown ip" do
      get "/geolocations", params: { ip: "8.8.8.8" }

      expect(response).to have_http_status(:not_found)
      expect(response_json["errors"].first["status"]).to eq("404")
    end

    it "returns 422 for an invalid ip" do
      get "/geolocations", params: { ip: "bogus" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 400 when both ip and url are given" do
      get "/geolocations", params: { ip: "8.8.8.8", url: "https://example.com" }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /geolocations" do
    it "deletes a geolocation by ip" do
      create(:geolocation, ip: "8.8.8.8")

      delete "/geolocations", params: { ip: "8.8.8.8" }

      expect(response).to have_http_status(:no_content)
      expect(Geolocation.count).to eq(0)
    end

    it "deletes a geolocation by url" do
      create(:geolocation, ip: "93.184.216.34", url: "https://example.com")

      delete "/geolocations", params: { url: "https://example.com" }

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for an unknown ip" do
      delete "/geolocations", params: { ip: "8.8.8.8" }

      expect(response).to have_http_status(:not_found)
    end

    it "returns 400 without ip or url" do
      delete "/geolocations"

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 422 for an invalid ip" do
      delete "/geolocations", params: { ip: "bogus" }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "unhandled errors" do
    it "returns a JSON:API 500 instead of an HTML error page" do
      allow(Geolocation).to receive(:order).and_raise(RuntimeError, "boom")

      get "/geolocations"

      expect(response).to have_http_status(:internal_server_error)
      expect(response_json["errors"].first["detail"]).to eq("An unexpected error occurred")
    end
  end
end
