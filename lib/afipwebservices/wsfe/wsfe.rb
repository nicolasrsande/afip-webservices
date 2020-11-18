module AfipWebservices
  # AFIP WSFEv1 Interface
  # This class is the main class of the "WSFEV1" API form AFIP
  #
  class WSFE
    # <------------------- CONFIGURATION -------------------> #
    include WSFEReference

    attr_accessor :wsaa, :cuit, :cbte_type, :cbte_pto_venta, :response, :batch

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/LineLength
    def initialize(attrs = {})
      @wsaa = WSAA.new(attrs.merge(service: 'wsfe'))
      @client = Client.new(Hash(attrs[:savon]).reverse_merge(wsdl: AfipWebservices::URLS[@wsaa.env][:wsfe], convert_request_keys_to: :camelcase))

      @cuit = attrs[:cuit] || AfipWebservices.default_cuit
      @cbte_type = attrs[:cbte_type]
      @cbte_pto_venta = attrs[:cbte_pto_venta]
      @batch = attrs[:batch] || []
    end

    # <------------------- INSTANCE METHODS -------------------> #

    # Main Auth Method
    # This method authorizes the invoices in the batch and returns the response from AFIP.
    # @return [Boolean]
    #
    def authorize
      response = send_request(:fecae_solicitar, auth.merge(setup_request_body))
      setup_response(response)
      authorized?
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
    def setup_request_structure
      { 'FeCAEReq' =>
            { 'FeCabReq' => setup_request_header,
              'FeDetReq' => {
                'FECAEDetRequest' => []
              } } }
    end

    # Sets up the Header Structure for the Message
    # @return [Hash]
    #
    def setup_request_header
      { 'CantReg' => @batch.size.to_s,
        'CbteTipo' => @cbte_type,
        'PtoVta' => @cbte_pto_venta }
    end

    def setup_request_body
      fe_cae_req = setup_request_structure
      fe_det_req = fe_cae_req['FeCAEReq']['FeDetReq']['FECAEDetRequest']
      last_cbte = next_cbte(pto_vta: @cbte_pto_venta, cbte_tipo: @cbte_type)
      @batch.each_with_index do |invoice, index|
        cbte = last_cbte + index
        fe_det_req << WSFEInvoice.setup_invoice(invoice, cbte)
      end
      fe_cae_req
    end

    def add_new_invoice(invoice)
      unless invoice.instance_of?(AfipWebservices::WSFEInvoice)
        raise(Error.new, 'invoice debe ser del tipo AfipWebservices::WSFEInvoice')
      end

      #if Bravo::IVA_CONDITION[Bravo.own_iva_cond][invoice.iva_condition][invoice_type] != bill_type_wsfe
      #  raise(Error.new, "The invoice doesn't correspond to this bill_type")
      #end TODO: adapt this

      @batch << invoice if invoice.validate_invoice_attrs
    end

    # <------------------- PRIVATE METHODS -------------------> #
    private

    # Main request method.
    # This method sends the request to the SOAP AFIP API and gets the response or error response.
    # @return [Hash]
    #
    def send_request(action, body = nil)
      response = @client.request(action, body).to_hash[:"#{action}_response"][:"#{action}_result"]
      raise ResponseError, Array.wrap(response[:errors][:err]) if response[:errors]

      response
    end

    # Response parser. Only works for the authorize method
    # @return [Hash] containing the header result, process_date, header and detail
    # TODO: Make a better parsing of batches
    #
    def setup_response(response)
      response_header = response[:fe_cab_resp]
      response_detail = response[:fe_det_resp][:fecae_det_response]
      response_detail = response_detail.respond_to?(:to_ary) ? response_detail : [response_detail]
      response_hash = { header_result: response_header[:resultado],
                        authorized_on: response_header[:fch_proceso],
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
