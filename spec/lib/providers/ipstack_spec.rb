require "rails_helper"

RSpec.describe Providers::Ipstack do
  subject(:provider) { described_class.new(api_key: "test-key") }

  let(:ip) { "8.8.8.8" }
  let(:endpoint) { "https://api.ipstack.com/#{ip}?access_key=test-key" }

  describe "#lookup" do
    context "when the lookup succeeds" do
      before do
        stub_request(:get, endpoint).to_return(
          status: 200,
          body: {
            ip: ip,
            country_code: "US",
            country_name: "United States",
            region_name: "California",
            city: "Mountain View",
            latitude: 37.386,
            longitude: -122.0838
          }.to_json
        )
      end

      it "returns a normalized result" do
        result = provider.lookup(ip)

        expect(result).to be_a(Providers::Result)
        expect(result.ip).to eq(ip)
        expect(result.country_code).to eq("US")
        expect(result.country).to eq("United States")
        expect(result.region).to eq("California")
        expect(result.city).to eq("Mountain View")
        expect(result.latitude).to eq(37.386)
        expect(result.longitude).to eq(-122.0838)
        expect(result.raw_data).to include("ip" => ip)
      end
    end

    context "when the API key is missing" do
      subject(:provider) { described_class.new(api_key: nil) }

      it "raises AuthenticationError without calling the API" do
        expect { provider.lookup(ip) }.to raise_error(Providers::AuthenticationError)
        expect(a_request(:get, /api\.ipstack\.com/)).not_to have_been_made
      end
    end

    context "when ipstack rejects the API key (code 101)" do
      before do
        stub_request(:get, endpoint).to_return(
          status: 200,
          body: {
            success: false,
            error: { code: 101, info: "You have not supplied a valid API Access Key." }
          }.to_json
        )
      end

      it "raises AuthenticationError" do
        expect { provider.lookup(ip) }
          .to raise_error(Providers::AuthenticationError, /Access Key/)
      end
    end

    context "when the rate limit is exhausted (code 104)" do
      before do
        stub_request(:get, endpoint).to_return(
          status: 200,
          body: {
            success: false,
            error: { code: 104, info: "Monthly usage limit reached." }
          }.to_json
        )
      end

      it "raises RateLimitError" do
        expect { provider.lookup(ip) }
          .to raise_error(Providers::RateLimitError, /usage limit/)
      end
    end

    context "when ipstack reports any other API error" do
      before do
        stub_request(:get, endpoint).to_return(
          status: 200,
          body: { success: false, error: { code: 301, info: "Invalid fields." } }.to_json
        )
      end

      it "raises UnavailableError" do
        expect { provider.lookup(ip) }.to raise_error(Providers::UnavailableError)
      end
    end

    context "when ipstack responds with a server error" do
      before do
        stub_request(:get, endpoint).to_return(status: 503, body: "")
      end

      it "raises UnavailableError" do
        expect { provider.lookup(ip) }
          .to raise_error(Providers::UnavailableError, /HTTP 503/)
      end
    end

    context "when the request times out" do
      before do
        stub_request(:get, endpoint).to_timeout
      end

      it "raises UnavailableError" do
        expect { provider.lookup(ip) }.to raise_error(Providers::UnavailableError)
      end
    end

    context "when the connection is refused" do
      before do
        stub_request(:get, endpoint).to_raise(Errno::ECONNREFUSED)
      end

      it "raises UnavailableError" do
        expect { provider.lookup(ip) }.to raise_error(Providers::UnavailableError)
      end
    end

    context "when ipstack returns malformed JSON" do
      before do
        stub_request(:get, endpoint).to_return(status: 200, body: "<html>oops</html>")
      end

      it "raises UnavailableError" do
        expect { provider.lookup(ip) }
          .to raise_error(Providers::UnavailableError, /malformed/)
      end
    end

    context "when ipstack returns an empty payload" do
      before do
        stub_request(:get, endpoint).to_return(status: 200, body: "{}")
      end

      it "raises UnavailableError" do
        expect { provider.lookup(ip) }
          .to raise_error(Providers::UnavailableError, /no data/)
      end
    end
  end
end
