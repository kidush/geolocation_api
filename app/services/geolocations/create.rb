module Geolocations
  class Create
    def initialize(ip: nil, url: nil, provider: Providers.current)
      @input = Input.new(ip: ip, url: url)
      @provider = provider
    end

    def call
      check_duplicate!

      result = @provider.lookup(@input.ip)

      Geolocation.create!(
        ip: @input.ip,
        url: @input.url,
        country_code: result.country_code,
        country: result.country,
        region: result.region,
        city: result.city,
        latitude: result.latitude,
        longitude: result.longitude,
        raw_data: result.raw_data
      )
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
      raise unless duplicate_error?(e)

      raise_duplicate!
    end

    private

    def check_duplicate!
      raise_duplicate! if Geolocation.exists?(ip: @input.ip)
    end

    def raise_duplicate!
      record = Geolocation.find_by(ip: @input.ip)
      raise DuplicateError.new(
        "A geolocation for IP #{@input.ip} is already stored",
        record: record
      )
    end

    def duplicate_error?(error)
      error.is_a?(ActiveRecord::RecordNotUnique) ||
        error.record&.errors&.of_kind?(:ip, :taken)
    end
  end
end
