require "rails_helper"

RSpec.describe Geolocations::Finder do
  describe "#call" do
    it "finds a record by ip" do
      record = create(:geolocation, ip: "8.8.8.8")

      expect(described_class.new(ip: "8.8.8.8").call).to eq(record)
    end

    it "finds a record by canonical ip regardless of input spelling" do
      record = create(:geolocation, ip: "2001:db8::ab")

      expect(described_class.new(ip: "2001:DB8::AB").call).to eq(record)
    end

    it "finds a record by url" do
      record = create(:geolocation, ip: "93.184.216.34", url: "https://example.com")

      expect(described_class.new(url: "https://example.com").call).to eq(record)
    end

    it "matches a bare-host url against the stored normalized url" do
      record = create(:geolocation, ip: "93.184.216.34", url: "https://example.com")

      expect(described_class.new(url: "example.com").call).to eq(record)
    end

    it "does not resolve DNS" do
      create(:geolocation, ip: "93.184.216.34", url: "https://example.com")
      allow(Resolv::DNS).to receive(:open)

      described_class.new(url: "https://example.com").call

      expect(Resolv::DNS).not_to have_received(:open)
    end

    it "raises RecordNotFound for an unknown ip" do
      expect { described_class.new(ip: "8.8.8.8").call }
        .to raise_error(ActiveRecord::RecordNotFound, /8\.8\.8\.8/)
    end

    it "raises RecordNotFound for an unknown url" do
      expect { described_class.new(url: "https://unknown.com").call }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "rejects invalid ip input" do
      expect { described_class.new(ip: "bogus").call }
        .to raise_error(Geolocations::InvalidInputError)
    end
  end
end
