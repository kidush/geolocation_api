module Providers
  class Base
    def lookup(ip)
      raise NotImplementedError, "#{self.class} must implement #lookup"
    end
  end
end
