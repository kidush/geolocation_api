module DnsStubs
  def stub_dns(host, ip)
    dns = instance_double(Resolv::DNS)
    allow(dns).to receive(:timeouts=)
    allow(dns).to receive(:getaddress).with(host).and_return(double(to_s: ip))
    allow(Resolv::DNS).to receive(:open).and_yield(dns)
  end

  def stub_dns_failure(host)
    dns = instance_double(Resolv::DNS)
    allow(dns).to receive(:timeouts=)
    allow(dns).to receive(:getaddress).with(host)
      .and_raise(Resolv::ResolvError, "no address for #{host}")
    allow(Resolv::DNS).to receive(:open).and_yield(dns)
  end
end

RSpec.configure do |config|
  config.include DnsStubs
end
