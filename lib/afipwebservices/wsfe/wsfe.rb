module AfipWebservices
  # AFIP WSFEv1 Interface
  # This class is the main class of the "WSFEV1" API form AFIP
  #
  class WSFE
    # <------------------- CONFIGURATION -------------------> #
    include WSFEReference

    attr_reader :wsaa, :cuit, :cbte_type, :cbte_pto_venta, :response

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/LineLength
    def initialize(attrs = {})
      @cuit = attrs[:cuit] || AfipWebservices.default_cuit
      @wsaa = WSAA.new(attrs.merge(service: 'wsfe'))
      @client = Client.new Hash(attrs[:savon]).reverse_merge(wsdl: AfipWebservices::URLS[@wsaa.env][:wsfe], convert_request_keys_to: :camelcase)
      @batch = attrs[:comprobantes] || []
      @cbte_type = attrs[:cbte_type]
      @cbte_pto_venta = attrs[:cbte_pto_venta]
    end

    # <------------------- INSTANCE METHODS -------------------> #

    # Main Auth Method
    # This method authorizes the invoices in the batch and returns the response from AFIP.
    # @return [Hash]
    #
    def authorize
      response = request :fecae_solicitar, auth.merge(setup_structure)
      setup_response(response)
    end

    # Returns the result of the authorization operation
    # @return [Boolean] the response result
    #
    def authorized?
      !response.nil? && response[:header_result] == 'A' && invoices_result
    end

    # Sets up the Message Structure for WSFE Webservice CAE Authorization
    # @return [Hash]
    #
    def setup_structure
      { 'FeCAEReq' =>
            { 'FeCabReq' => setup_header,
              'FeDetReq' => {
                'FECAEDetRequest' => setup_request
              } } }
    end

    # <------------------- PRIVATE METHODS -------------------> #
    private

    # Main request method.
    # This method sends the request to the SOAP AFIP API and gets the response or error response.
    # @return [Hash]
    #
    def request(action, body = nil)
      response = @client.request(action, body).to_hash[:"#{action}_response"][:"#{action}_result"]
      raise ResponseError, Array.wrap(response[:errors][:err]) if response[:errors]
      response
    end

    # Sets up the Header Structure for the Message
    # @return [Hash]
    #
    def setup_header
      { 'CantReg' => @batch.size.to_s,
        'CbteTipo' => @cbte_type,
        'PtoVta' => @cbte_pto_venta }
    end

    # Setup the batch cbtes structure for merging in body
    # @return [Hash]
    #
    def setup_request
      request = {}
      @batch.each_with_index do |invoice, index|
        last_cbte_options = { 'PtoVta' => cbte_pto_venta, 'CbteTipo' => cbte_type }
        cbte = last_cbte(last_cbte_options) + index
        request << WSFEInvoice.setup_invoice(invoice, cbte)
      end
      request
    end

    # Response parser. Only works for the authorize method
    # @return [Hash] containing the header result, process_date, header and detail
    # TODO: Make a better parsing of batches
    #
    def setup_response(response)
      response_header = response[:fe_cab_resp]
      response_detail = response[:fe_det_resp][:fecae_det_response]

      # If there's only one invoice in the batch, put it in an array
      response_detail = response_detail.respond_to?(:to_ary) ? response_detail : [response_detail]

      response_hash = { header_result:   response_header[:resultado],
                        authorized_on:   response_header[:fch_proceso],
                        header_response: response_header,
                        detail_response: response_detail }

      self.response = response_hash
    end

    # Returns true if the whole batch is authorized
    # @return [Boolean]
    #
    def invoices_result
      response[:detail_response].map { |invoice| invoice[:resultado] == 'A' }.all?
    end

    # <------------------- END WSFE CLASS -------------------> #
  end
  # <------------------- END AFIPWEBSERVICES MODULE -------------------> #
end
