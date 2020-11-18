module AfipWebservices
  # Module for doing type changes between ruby objects and AFIP expected
  # types.
  #
  module TypesConversion

    # Returns the current day in string format
    # It is used if no dates are specified in the Hash
    # @return [Time]
    #
    def today
      Time.now
    end

    # <------------------- END MODULE -------------------> #
  end
  # <------------------- END MODULE -------------------> #
end
