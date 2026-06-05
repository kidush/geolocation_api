module Providers
  Result = Struct.new(
    :ip,
    :country_code,
    :country,
    :region,
    :city,
    :latitude,
    :longitude,
    :raw_data,
    keyword_init: true
  )
end
