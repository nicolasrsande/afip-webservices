module AfipWebservices
  class Error < StandardError
    def code?(_code)
      false
    end
  end
end