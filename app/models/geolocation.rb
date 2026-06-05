class Geolocation < ApplicationRecord
  before_validation :normalize_ip

  validates :ip, presence: true, uniqueness: true
  validate :ip_must_be_valid_address

  private

  def normalize_ip
    self.ip = IPAddr.new(ip.strip).to_s if ip.present?
  rescue IPAddr::InvalidAddressError
    nil
  end

  def ip_must_be_valid_address
    return if ip.blank?

    IPAddr.new(ip)
  rescue IPAddr::InvalidAddressError
    errors.add(:ip, "is not a valid IP address")
  end
end
