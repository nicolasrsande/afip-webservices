module AfipWebservices
  module CoreExt
    module Hash
      def select_keys *keys
        select { |k, _| keys.include? k }
      end
    end
  end
end

class Hash
  include AfipWebservices::CoreExt::Hash
end