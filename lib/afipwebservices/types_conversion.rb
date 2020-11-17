module AfipWebservices
  # Module for doing type changes between ruby objects and AFIP expected
  # types.
  #
  module TypesConversion

    # Parses the date to string format
    # It is used to comply to AFIP Date Format
    # @return [String]
    #
    def parse_date(date) # TODO: Create a types class?
      return nil if date.nil?

      date.strftime('%Y%m%d')
    end

    # Returns the current day in string format
    # It is used if no dates are specified in the Hash
    # @return [String]
    #
    def today
      Time.new.strftime('%Y%m%d')
    end
    
    # <------------------- END MODULE -------------------> #
  end
  # <------------------- END MODULE -------------------> #
end
