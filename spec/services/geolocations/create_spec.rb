require "rails_helper"

RSpec.describe Geolocations::Create do
  let(:provider) { Providers::Fake.new }

  describe "#call" do
    it "stores a geolocation for an IP" do
      record = described_class.new(ip: "8.8.8.8", provider: provider).call

      expect(record).to be_persisted
      expect(record.ip).to eq("8.8.8.8")
      expect(record.url).to be_nil
      expect(record.country_code).to eq("US")
      expect(record.city).to eq("Mountain View")
      expect(record.raw_data).to include("provider" => "fake")
    end

    it "stores a geolocation for a URL with its resolved IP" do
      stub_dns("example.com", "93.184.216.34")

      record = described_class.new(url: "https://example.com", provider: provider).call

      expect(record.ip).to eq("93.184.216.34")
      expect(record.url).to eq("https://example.com")
    end

    it "raises DuplicateError when the IP is already stored" do
      existing = create(:geolocation, ip: "8.8.8.8")

      expect { described_class.new(ip: "8.8.8.8", provider: provider).call }
        .to raise_error(Geolocations::DuplicateError) do |error|
          expect(error.record).to eq(existing)
        end
    end

    it "raises DuplicateError when a URL resolves to an already stored IP" do
      create(:geolocation, ip: "93.184.216.34")
      stub_dns("example.com", "93.184.216.34")

      expect { described_class.new(url: "https://example.com", provider: provider).call }
        .to raise_error(Geolocations::DuplicateError)
    end

    it "does not call the provider for a duplicate" do
      create(:geolocation, ip: "8.8.8.8")
      allow(provider).to receive(:lookup)

      begin
        described_class.new(ip: "8.8.8.8", provider: provider).call
      rescue Geolocations::DuplicateError
        nil
      end

      expect(provider).not_to have_received(:lookup)
    end

    it "propagates provider errors without persisting anything" do
      allow(provider).to receive(:lookup)
        .and_raise(Providers::UnavailableError, "down")

      expect { described_class.new(ip: "8.8.8.8", provider: provider).call }
        .to raise_error(Providers::UnavailableError)
      expect(Geolocation.count).to eq(0)
    end

    it "propagates invalid input errors" do
      expect { described_class.new(ip: "bogus", provider: provider).call }
        .to raise_error(Geolocations::InvalidInputError)
    end
  end
end
