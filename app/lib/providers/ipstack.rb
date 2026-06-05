module Providers
  class Ipstack < Base
    BASE_URL = "https://api.ipstack.com".freeze
    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 5

    AUTH_ERROR_CODES = [ 101, 102, 103 ].freeze
    RATE_LIMIT_ERROR_CODES = [ 104 ].freeze

    def initialize(api_key: ENV["IPSTACK_API_KEY"], connection: nil)
      @api_key = api_key
      @connection = connection || build_connection
    end

    def lookup(ip)
      raise AuthenticationError, "IPSTACK_API_KEY is not configured" if @api_key.blank?

      response = request(ip)
      payload = parse(response)
      check_api_error!(payload)
      build_result(ip, payload)
    end

    private

    def build_connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.options.open_timeout = OPEN_TIMEOUT
        conn.options.timeout = READ_TIMEOUT
      end
    end

    def request(ip)
      response = @connection.get("/#{ip}", access_key: @api_key)
      unless response.success?
        raise UnavailableError, "ipstack responded with HTTP #{response.status}"
      end

      response
    rescue Faraday::Error => e
      raise UnavailableError, "ipstack request failed: #{e.message}"
    end

    def parse(response)
      JSON.parse(response.body)
    rescue JSON::ParserError
      raise UnavailableError, "ipstack returned a malformed response"
    end

    def check_api_error!(payload)
      # ipstack signals errors with HTTP 200 and a {"success": false} body
      return unless payload.is_a?(Hash) && payload["success"] == false

      error = payload["error"] || {}
      code = error["code"]
      message = error["info"] || "ipstack reported an unknown error"

      raise AuthenticationError, message if AUTH_ERROR_CODES.include?(code)
      raise RateLimitError, message if RATE_LIMIT_ERROR_CODES.include?(code)
      raise UnavailableError, message
    end

    def build_result(ip, payload)
      unless payload.is_a?(Hash) && payload["ip"].present?
        raise UnavailableError, "ipstack returned no data for #{ip}"
      end

      Result.new(
        ip: payload["ip"],
        country_code: payload["country_code"],
        country: payload["country_name"],
        region: payload["region_name"],
        city: payload["city"],
        latitude: payload["latitude"],
        longitude: payload["longitude"],
        raw_data: payload
      )
    end
  end
end
