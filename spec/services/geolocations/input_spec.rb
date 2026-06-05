require "rails_helper"

RSpec.describe Geolocations::Input do
  describe "ip input" do
    it "accepts a valid IPv4 address" do
      input = described_class.new(ip: "8.8.8.8")
      expect(input.ip).to eq("8.8.8.8")
      expect(input.url).to be_nil
    end

    it "canonicalizes IPv6 addresses" do
      input = described_class.new(ip: " 2001:DB8::AB ")
      expect(input.ip).to eq("2001:db8::ab")
    end

    it "rejects a malformed IP" do
      expect { described_class.new(ip: "999.999.999.999") }
        .to raise_error(Geolocations::InvalidInputError, /not a valid IP/)
    end

    it "rejects a random string" do
      expect { described_class.new(ip: "not-an-ip") }
        .to raise_error(Geolocations::InvalidInputError)
    end
  end

  describe "url input" do
    it "resolves the host to an IP" do
      stub_dns("github.com", "140.82.121.4")

      input = described_class.new(url: "https://github.com/some/path")
      expect(input.ip).to eq("140.82.121.4")
      expect(input.url).to eq("https://github.com/some/path")
    end

    it "accepts a bare host by assuming https" do
      stub_dns("example.com", "93.184.216.34")

      input = described_class.new(url: "example.com")
      expect(input.url).to eq("https://example.com")
      expect(input.ip).to eq("93.184.216.34")
    end

    it "downcases the host but preserves the rest of the URL" do
      stub_dns("example.com", "93.184.216.34")

      input = described_class.new(url: "https://EXAMPLE.com/Path?Query=1")
      expect(input.url).to eq("https://example.com/Path?Query=1")
    end

    it "skips DNS when the host is an IP literal" do
      input = described_class.new(url: "https://8.8.8.8/path")
      expect(input.ip).to eq("8.8.8.8")
    end

    it "rejects an unparseable URL" do
      expect { described_class.new(url: "http://[broken") }
        .to raise_error(Geolocations::InvalidInputError, /not a valid URL/)
    end

    it "rejects input without a host" do
      expect { described_class.new(url: "https://") }
        .to raise_error(Geolocations::InvalidInputError)
    end

    it "raises when the host cannot be resolved" do
      stub_dns_failure("nonexistent.invalid")

      expect { described_class.new(url: "https://nonexistent.invalid") }
        .to raise_error(Geolocations::InvalidInputError, /Could not resolve/)
    end

    it "skips DNS resolution when resolve_dns is false" do
      input = described_class.new(url: "https://example.com", resolve_dns: false)
      expect(input.ip).to be_nil
      expect(input.url).to eq("https://example.com")
    end
  end

  describe "parameter presence" do
    it "rejects missing input" do
      expect { described_class.new }
        .to raise_error(Geolocations::BadRequestError, /Provide either/)
    end

    it "rejects blank input" do
      expect { described_class.new(ip: " ", url: "") }
        .to raise_error(Geolocations::BadRequestError)
    end

    it "rejects ip and url given together" do
      expect { described_class.new(ip: "8.8.8.8", url: "https://example.com") }
        .to raise_error(Geolocations::BadRequestError, /not both/)
    end
  end
end
