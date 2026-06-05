require "rails_helper"

RSpec.describe Providers::Fake do
  subject(:provider) { described_class.new }

  describe "#lookup" do
    it "returns canned data for a known IP" do
      result = provider.lookup("8.8.8.8")

      expect(result).to be_a(Providers::Result)
      expect(result.ip).to eq("8.8.8.8")
      expect(result.country_code).to eq("US")
      expect(result.city).to eq("Mountain View")
    end

    it "returns deterministic fallback data for an unknown IP" do
      result = provider.lookup("203.0.113.99")

      expect(result.ip).to eq("203.0.113.99")
      expect(result.country_code).to eq("DE")
      expect(result.raw_data).to include("provider" => "fake")
    end

    it "never performs HTTP requests" do
      provider.lookup("8.8.8.8")

      expect(a_request(:any, /.*/)).not_to have_been_made
    end
  end
end
