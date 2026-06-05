module Geolocations
  class Finder
    def initialize(ip: nil, url: nil)
      @input = Input.new(ip: ip, url: url, resolve_dns: false)
    end

    def call
      record =
        if @input.ip
          Geolocation.find_by(ip: @input.ip)
        else
          Geolocation.find_by(url: @input.url)
        end

      unless record
        raise ActiveRecord::RecordNotFound,
              "No geolocation stored for #{lookup_description}"
      end

      record
    end

    private

    def lookup_description
      @input.ip ? "ip #{@input.ip}" : "url #{@input.url}"
    end
  end
end
