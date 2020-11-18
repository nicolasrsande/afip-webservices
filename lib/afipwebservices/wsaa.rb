module AfipWebservices
  # Main Auth Class. WSAA
  # Authorization class. Handles interactions with the WSAA, to provide
  # valid key and signature that will last for a day.
  #
  class WSAA

    # <------------------- CONFIGURATION -------------------> #
    attr_reader :key, :cert, :service, :ta, :cuit, :client, :env, :ta_path

    # WSAA Class initializes with the minimal params:
    # WSAA.new(key, cert, service)
    # --> Optionals: Cuit (default defined by global variable)
    # --> Optionals: Service (default defined to wsfe if not indicated)
    #
    def initialize(options = {})
      @key = options[:key] || AfipWebservices.pkey # Default is defined with global variable
      @cert = options[:cert] || AfipWebservices.cert # Default is defined with global variable
      @cuit = options[:cuit] || AfipWebservices.default_cuit # Default is defined with global variable
      @service = options[:service] || 'wsfe' # Default is defined to 'wsfe' - each service set-up this automatically

      @env = AfipWebservices.env # Defined with global variable, you MUST include ENV in initializer
      @url = AfipWebservices::URLS[env][:wsaa]
      @client = Client.new(Hash(options[:savon]).reverse_merge(wsdl: @url))
      @ta_path = options[:ta_path] || File.join(Dir.pwd, 'tmp', "#{@cuit}-#{@env}-#{@service}-ta.dump")
    end

    # <------------------- PUBLIC METHODS -------------------> #

    # Main Method, generates the request to the AFIP Soap API and returns the response ta.
    # Then it saves the ta in /tmp file
    #
    def login
      response = @client.request(:login_cms, in0: tra(@key, @cert, @service))
      ta = Nokogiri::XML(Nokogiri::XML(response.to_xml).text)
      {
        token: ta.css('token').text,
        sign: ta.css('sign').text,
        generation_time: from_xsd_datetime(ta.css('generationTime').text),
        expiration_time: from_xsd_datetime(ta.css('expirationTime').text)
      }
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

    # Generates, sign and codify and returns the tra.
    # @return [String] with the tra codified and signed
    #
    def tra(key, cert, service)
      codify_tra(sign_tra(build_tra(service), key, cert))
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
    def codify_tra(pkcs8)
      pkcs8.to_pem.lines.to_a[1..-2].join
    end

    # <------------------- PRIVATE METHODS -------------------> #
    private

    # Returns the ta if exists or generates a new one
    # @return [String]
    #
    def return_ta
      @ta ||= restore_ta
      return @ta unless ta_expired?(@ta)

      @ta = login
      persist_ta(@ta)
      @ta
    end

    # @return [Time]
    # @return [nil]
    #
    def from_xsd_datetime(str)
      Time.parse(str)
    rescue StandardError
      nil
    end

    # Check if the ta has expired
    # @return [Boolean]
    #
    def ta_expired?(ta_dump)
      ta_dump.nil? || ta_dump[:expiration_time] <= Time.now
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
    def persist_ta(ta_dump)
      FileUtils.mkdir_p(File.dirname(@ta_path))
      File.open(@ta_path, 'wb') { |f| f.write(Marshal.dump(ta_dump)) }
    end

    # <------------------- END WSAA CLASS -------------------> #
  end
  # <------------------- END AFIPWEBSERVICES MODEL -------------------> #
end
