module Providers
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class RateLimitError < Error; end
  class UnavailableError < Error; end
  class UnknownProviderError < StandardError; end

  REGISTRY = {
    "ipstack" => "Providers::Ipstack",
    "fake" => "Providers::Fake"
  }.freeze

  def self.current
    name = ENV.fetch("GEOLOCATION_PROVIDER", "fake").downcase

    class_name = REGISTRY[name]
    unless class_name
      raise UnknownProviderError,
            "Unknown geolocation provider #{name.inspect}. Valid values: #{REGISTRY.keys.join(', ')}"
    end

    class_name.constantize.new
  end
end
