provider = Providers::Fake.new

[
  { ip: "8.8.8.8", url: "https://dns.google" },
  { ip: "1.1.1.1", url: "https://cloudflare.com" },
  { ip: "187.6.0.1", url: nil },
  { ip: "93.184.216.34", url: "https://example.com" },
  { ip: "140.82.121.4", url: "https://github.com" }
].each do |seed|
  next if Geolocation.exists?(ip: seed[:ip])

  result = provider.lookup(seed[:ip])

  Geolocation.create!(
    ip: seed[:ip],
    url: seed[:url],
    country_code: result.country_code,
    country: result.country,
    region: result.region,
    city: result.city,
    latitude: result.latitude,
    longitude: result.longitude,
    raw_data: result.raw_data
  )
end

puts "Seeded #{Geolocation.count} geolocations"
