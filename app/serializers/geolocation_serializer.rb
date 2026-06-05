class GeolocationSerializer
  include JSONAPI::Serializer

  set_type :geolocation

  attributes :ip, :url, :country_code, :country, :region, :city,
             :latitude, :longitude, :created_at, :updated_at
end
