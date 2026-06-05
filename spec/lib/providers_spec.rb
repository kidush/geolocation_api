require "rails_helper"

RSpec.describe Providers do
  describe ".current" do
    around do |example|
      original = ENV["GEOLOCATION_PROVIDER"]
      example.run
    ensure
      ENV["GEOLOCATION_PROVIDER"] = original
    end

    it "defaults to the fake provider" do
      ENV.delete("GEOLOCATION_PROVIDER")
      expect(described_class.current).to be_a(Providers::Fake)
    end

    it "returns the ipstack provider when configured" do
      ENV["GEOLOCATION_PROVIDER"] = "ipstack"
      expect(described_class.current).to be_a(Providers::Ipstack)
    end

    it "is case-insensitive" do
      ENV["GEOLOCATION_PROVIDER"] = "IpStack"
      expect(described_class.current).to be_a(Providers::Ipstack)
    end

    it "raises for an unknown provider" do
      ENV["GEOLOCATION_PROVIDER"] = "nonsense"
      expect { described_class.current }
        .to raise_error(Providers::UnknownProviderError, /nonsense/)
    end
  end
end
