module Providers
  class Fake < Base
    KNOWN_IPS = {
      "8.8.8.8" => {
        country_code: "US", country: "United States",
        region: "California", city: "Mountain View",
        latitude: 37.386, longitude: -122.0838
      },
      "1.1.1.1" => {
        country_code: "AU", country: "Australia",
        region: "Queensland", city: "South Brisbane",
        latitude: -27.4766, longitude: 153.0166
      },
      "187.6.0.1" => {
        country_code: "BR", country: "Brazil",
        region: "Sao Paulo", city: "São Paulo",
        latitude: -23.5505, longitude: -46.6333
      }
    }.freeze

    DEFAULT_ATTRIBUTES = {
      country_code: "DE", country: "Germany",
      region: "Berlin", city: "Berlin",
      latitude: 52.52, longitude: 13.405
    }.freeze

    def lookup(ip)
      attributes = KNOWN_IPS.fetch(ip, DEFAULT_ATTRIBUTES)

      Result.new(
        ip: ip,
        raw_data: { "ip" => ip, "provider" => "fake" }.merge(attributes.transform_keys(&:to_s)),
        **attributes
      )
    end
  end
end
