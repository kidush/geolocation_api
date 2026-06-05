require "resolv"

module Geolocations
  class Input
    DNS_TIMEOUT = 3

    attr_reader :ip, :url

    def initialize(ip: nil, url: nil, resolve_dns: true)
      ip = ip.presence
      url = url.presence

      raise BadRequestError, "Provide either an ip or a url parameter" if ip.blank? && url.blank?
      raise BadRequestError, "Provide either an ip or a url parameter, not both" if ip.present? && url.present?

      if ip
        @ip = canonical_ip(ip)
      else
        @url = normalize_url(url)
        @ip = resolve_host(host_of(@url)) if resolve_dns
      end
    end

    private

    def canonical_ip(value)
      IPAddr.new(value.strip).to_s
    rescue IPAddr::InvalidAddressError
      raise InvalidInputError, "#{value.inspect} is not a valid IP address"
    end

    def normalize_url(value)
      value = value.strip
      value = "https://#{value}" unless value.match?(%r{\A[a-zA-Z][a-zA-Z0-9+.-]*://})

      uri = URI.parse(value)
      raise InvalidInputError, "#{value.inspect} is not a valid URL" if uri.host.blank?

      uri.host = uri.host.downcase
      uri.to_s
    rescue URI::InvalidURIError
      raise InvalidInputError, "#{value.inspect} is not a valid URL"
    end

    def host_of(url)
      URI.parse(url).hostname
    end

    def resolve_host(host)
      return IPAddr.new(host).to_s if ip_literal?(host)

      address = Resolv::DNS.open do |dns|
        dns.timeouts = DNS_TIMEOUT
        dns.getaddress(host)
      end
      address.to_s
    rescue Resolv::ResolvError, Resolv::ResolvTimeout
      raise InvalidInputError, "Could not resolve host #{host.inspect}"
    end

    def ip_literal?(host)
      IPAddr.new(host)
      true
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
