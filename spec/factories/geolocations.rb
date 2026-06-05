FactoryBot.define do
  factory :geolocation do
    sequence(:ip) { |n| "13.37.#{(n / 256) % 256}.#{n % 256}" }
    url { nil }
    country_code { "US" }
    country { "United States" }
    region { "California" }
    city { "Mountain View" }
    latitude { 37.386 }
    longitude { -122.0838 }
    raw_data { { "ip" => ip, "country_code" => "US" } }

    trait :with_url do
      url { "https://example.com" }
    end
  end
end
