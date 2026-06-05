require "rails_helper"

RSpec.describe Geolocation, type: :model do
  subject(:geolocation) { build(:geolocation) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:ip) }

    it "rejects a duplicate ip" do
      create(:geolocation, ip: "8.8.8.8")
      duplicate = build(:geolocation, ip: "8.8.8.8")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ip]).to include("has already been taken")
    end

    it "treats differently-cased IPv6 addresses as the same address" do
      create(:geolocation, ip: "2001:db8::ab")
      duplicate = build(:geolocation, ip: "2001:DB8::AB")

      expect(duplicate).not_to be_valid
    end

    it "is valid with a valid IPv4 address" do
      geolocation.ip = "8.8.8.8"
      expect(geolocation).to be_valid
    end

    it "is valid with a valid IPv6 address" do
      geolocation.ip = "2001:db8::1"
      expect(geolocation).to be_valid
    end

    it "is invalid with a malformed IP" do
      geolocation.ip = "999.999.999.999"
      expect(geolocation).not_to be_valid
      expect(geolocation.errors[:ip]).to include("is not a valid IP address")
    end

    it "is invalid with a random string" do
      geolocation.ip = "not-an-ip"
      expect(geolocation).not_to be_valid
    end

    it "allows a blank url" do
      geolocation.url = nil
      expect(geolocation).to be_valid
    end
  end

  describe "normalization" do
    it "stores the canonical IP form" do
      geolocation.ip = " 2001:DB8::AB "
      geolocation.valid?
      expect(geolocation.ip).to eq("2001:db8::ab")
    end
  end

  describe "database constraints" do
    it "rejects a duplicate ip at the database level" do
      create(:geolocation, ip: "8.8.8.8")
      duplicate = build(:geolocation, ip: "8.8.8.8")

      expect { duplicate.save!(validate: false) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
