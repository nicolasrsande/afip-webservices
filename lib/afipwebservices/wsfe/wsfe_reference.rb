module AfipWebservices
  # This module contains all reference methods provided by the
  # AFIP WSFE API Endpoints
  #
  module WSFEReference
    # Check the AFIP Server Status
    # @return [Hash]
    #
    def fe_dummy
      request :fe_dummy
    end

    # Returns the auth Hash for the designated CUIT from WSAA class
    # @return [Hash]
    #
    def auth
      { auth: wsaa.auth.merge(cuit: cuit) }
    end

    # Returns the last cbte authorized for a given punto_venta and cbte_type
    # The options should contain [ PtoVta - CbteTipo ]
    # @return [Integer]
    #
    def last_cbte(opciones)
      send_request(:fe_comp_ultimo_autorizado, auth.merge(opciones))[:cbte_nro].to_i
    end

    def next_cbte(opciones)
      last_cbte(opciones) + 1
    end
    
    # Returns all valid cbte_types from AFIP Servers
    # Can be used to validations TODO:
    # @return [Hash]
    #
    def cbte_types
      r = send_request :fe_param_get_tipos_cbte, auth
      x2r get_array(r, :cbte_tipo), id: :integer, fch_desde: :date, fch_hasta: :date
    end

    # Returns all valid optionals types from AFIP Servers
    # Can be used to validations
    # @return [Hash]
    #
    def optionals_types
      r = send_request :fe_param_get_tipos_opcional, auth
      x2r get_array(r, :tipos_opcional), id: :integer, fch_desde: :date, fch_hasta: :date
    end

    # Returns all valid document types from AFIP Servers
    # Can be used to validations
    # @return [Hash]
    #
    def document_types
      r = send_request :fe_param_get_tipos_doc, auth
      x2r get_array(r, :doc_tipo), id: :integer, fch_desde: :date, fch_hasta: :date
    end

    # Returns all valid afip concepts types from AFIP Servers
    # Can be used to validations
    # @return [Hash]
    #
    def afip_concept_types
      r = send_request :fe_param_get_tipos_concepto, auth
      x2r get_array(r, :concepto_tipo), id: :integer, fch_desde: :date, fch_hasta: :date
    end

    # Returns all valid currencies types from AFIP Servers
    # Can be used to validations
    # @return [Hash]
    #
    def currency_types
      r = send_request :fe_param_get_tipos_monedas, auth
      x2r get_array(r, :moneda), fch_desde: :date, fch_hasta: :date
    end

    # Returns all valid iva aliquots types from AFIP Servers
    # Can be used to validations
    # @return [Hash]
    #
    def iva_types
      r = send_request :fe_param_get_tipos_iva, auth
      x2r get_array(r, :iva_tipo), id: :integer, fch_desde: :date, fch_hasta: :date
    end

    # Returns all valid other taxes types from AFIP Servers
    # Can be used to validations
    # @return [Hash]
    #
    def other_taxes_types
      r = send_request :fe_param_get_tipos_tributos, auth
      x2r get_array(r, :tributo_tipo), id: :integer, fch_desde: :date, fch_hasta: :date
    end

    # Returns all valid sale_points from AFIP Servers
    # Can be used to validations
    # @return [Hash]
    #
    def sale_points_list
      r = send_request :fe_param_get_ptos_venta, auth
      x2r get_array(r, :pto_venta), nro: :integer, fch_baja: :date, bloqueado: :boolean
    end

    # Returns and get the current oficial currency value from AFIP Servers
    # @return [Hash]
    #
    def currency_cot(moneda_id)
      send_request(:fe_param_get_cotizacion, auth.merge(mon_id: moneda_id))[:result_get][:mon_cotiz].to_f
    end

    # Returns and get the max batch register admitted in one request
    # This is useful for separating batches in mass authorizations
    # @return [Hash]
    #
    def cant_max_registros_x_lote
      send_request(:fe_comp_tot_x_request, auth)[:reg_x_req].to_i
    end

    # END REFERENCE MODULE #
  end
  # END MAIN MODULE #
end
