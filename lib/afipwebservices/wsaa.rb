module AfipWebservices
  # Main Auth Class. WSAA
  # Authorization class. Handles interactions with the WSAA, to provide
  # valid key and signature that will last for a day.
  #
  class WSAA

    # <------------------- CONFIGURATION -------------------> #
    attr_reader :key, :cert, :service, :ta, :cuit, :client, :env, :ta_path

    def initialize(options = {})
      @env = AfipWebservices.env
      @url = AfipWebservices::URLS[env][:wsaa]
      @key = options[:key] || AfipWebservices.pkey
      @cert = options[:cert] || AfipWebservices.cert
      @service = options[:service] || 'wsfe'
      @cuit = options[:cuit] || AfipWebservices.default_cuit
      @client = Client.new(Hash(options[:savon]).reverse_merge(wsdl: @url))
      @ta_path = options[:ta_path] || File.join(Dir.pwd, 'tmp', "#{@cuit}-#{@env}-#{@service}-ta.dump")
    end

    # <------------------- INSTANCE METHODS -------------------> #

    # Main Method, generates the request to the AFIP Soap API and returns the response ta.
    # Then it saves the ta in /tmp file
    #
    def login
      response = @client.request :login_cms, in0: tra(@key, @cert, @service)
      ta = Nokogiri::XML(Nokogiri::XML(response.to_xml).text)
      {
        token: ta.css('token').text,
        sign: ta.css('sign').text,
        generation_time: from_xsd_datetime(ta.css('generationTime').text),
        expiration_time: from_xsd_datetime(ta.css('expirationTime').text)
      }
    end

    # Generates, sign and codify and returns the tra.
    # @return [String] with the tra codified and signed
    #
    def tra(key, cert, service)
      codify_tra sign_tra(build_tra(service), key, cert)
    end

    # Returns the auth hash from ta or generates a new one
    # This method is used to request the auth hash from the api services
    # @return [Hash]
    #
    def auth
      ta = return_ta
      { token: ta[:token], sign: ta[:sign] }
    end

    # Builds the xml for the 'Ticket de Requerimiento de Acceso'
    # @return [Xml] containing the request body
    #
    def build_tra(service)
      now = Time.now - 120
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct!
      xml.loginTicketRequest version: 1 do
        xml.header do
          xml.uniqueId now.strftime('%s')
          xml.generationTime now.strftime('%FT%T%:z')
          xml.expirationTime (now + (1 * 60 * 60)).strftime('%FT%T%:z')
        end
        xml.service service
      end
    end

    # Signs the tra with OpenSSL
    # @return [String]
    #
    def sign_tra(tra, key, crt)
      key = OpenSSL::PKey::RSA.new(File.read(key))
      crt = OpenSSL::X509::Certificate.new(File.read(crt))
      OpenSSL::PKCS7.sign(crt, key, tra)
    end

    # Codifies the tra in pkcs8
    # @return [String]
    #
    def codify_tra(pkcs7)
      pkcs7.to_pem.lines.to_a[1..-2].join
    end

    # <------------------- PRIVATE METHODS -------------------> #
    private

    # Returns the ta if exists or generates a new one
    # @return [String]
    #
    def return_ta
      @ta ||= restore_ta
      if ta_expired?(@ta)
        @ta = login
        persist_ta @ta
      end
      @ta
    end

    # @return [Time]
    # @return [nil]
    #
    def from_xsd_datetime(str)
      Time.parse(str)
    rescue
      nil
    end

    # Check if the ta has expired
    # @return [Boolean]
    #
    def ta_expired?(ta)
      ta.nil? || ta[:expiration_time] <= Time.now
    end

    # Restores the ta from tmp file if exists
    # @return [String]
    #
    def restore_ta
      Marshal.load(File.read(@ta_path)) if File.exist?(@ta_path) && !File.zero?(@ta_path)
    end

    # Persists the ta in a /tmp file
    # @return [Integer]
    #
    def persist_ta(ta)
      FileUtils.mkdir_p(File.dirname(@ta_path))
      File.open(@ta_path, 'wb') { |f| f.write(Marshal.dump(ta)) }
    end

    # <------------------- END WSAA CLASS -------------------> #
  end
  # <------------------- END AFIPWEBSERVICES MODEL -------------------> #
end
