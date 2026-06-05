module Geolocations
  class BadRequestError < StandardError; end

  class InvalidInputError < StandardError; end

  class DuplicateError < StandardError
    attr_reader :record

    def initialize(message, record: nil)
      super(message)
      @record = record
    end
  end
end
