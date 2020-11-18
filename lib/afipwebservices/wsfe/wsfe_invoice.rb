module AfipWebservices
  # This is the Invoice Class witch will map, order and generate body params to the Afip Auth.
  # Define la estructura que deben tener los comprobantes para ser parseados al formato de la API.
  #
  class WSFEInvoice

    # <------------------- CONFIGURATION -------------------> #
    include TypesConversion

    attr_accessor :issue_date, :due_date, :date_from, :date_to, :document_type, :document_number, :cbte_number,
                  :net, :iva, :exempt, :total, :other_taxes, :currency, :currency_cot, :afip_concept,
                  :iva_detail, :other_taxes_detail, :cbtes_asoc_detail

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def initialize(params = {})
      @issue_date = params[:issue_date] || today
      @due_date = params[:due_date] || today
      @date_from = params[:date_from] || today
      @date_to = params[:date_to] || today
      @document_type = params[:document_type] || 80 # Default to "CUIT"
      @document_number = params[:document_number]
      @cbte_number = params[cbte_number]
      @net = params[:net].to_f.round(2) || 0.00
      @exempt = params[:exempt].to_f.round(2) || 0.00
      @iva = params[:iva].to_f.round(2) || 0.00
      @other_taxes = params[:other_taxes].to_f.round(2) || 0.00
      @total = params[:total]
      @currency = params[:currency] || 'PES' # Default: "Pesos"
      @currency_cot = params[:currency_cot] || 1 # Default: 1
      @afip_concept = params[:afip_concept] || 3 # Default to "Productos y Servicios"
      @iva_detail = params[:iva_detail] || [] # Format: [ {}, {}, ..., {} ]
      @other_taxes_detail = params[:other_taxes_detail] || [] # Format: [ {}, {}, ..., {} ]
      @cbtes_asoc = params[cbtes_asoc_detail] || [] # Format: [ {}, {}, ..., {} ]
    end

    # <------------------- INSTANCE METHODS -------------------> #

    # Invoice to => Afip Hash
    # Returns the Hash with invoice detail
    # This method converts and maps invoice object values to the AFIP API required format.
    # @return [Hash]
    #
    def self.setup_invoice(invoice, cbte_index)
      detail = {}
      detail['Concepto']      = invoice.afip_concept
      detail['DocTipo']       = invoice.document_type
      detail['DocNro']        = invoice.document_number
      detail['CbteDesde']     = detail['CbteHasta'] = invoice.cbte_number || cbte_index
      detail['CbteFch']       = invoice.issue_date.strftime('%Y%m%d')
      detail['ImpTotal']      = invoice.total
      detail['ImpTotConc']    = 0.00
      detail['ImpNeto']       = invoice.net
      detail['ImpOpEx']       = invoice.exempt
      detail['ImpTrib']       = invoice.other_taxes
      detail['ImpIVA']        = invoice.iva
      detail['FchServDesde']  = invoice.date_from.strftime('%Y%m%d')
      detail['FchServHasta']  = invoice.date_to.strftime('%Y%m%d')
      detail['FchVtoPago']    = invoice.due_date.strftime('%Y%m%d')
      detail['MonId']         = invoice.currency
      detail['MonCotiz']      = invoice.currency_cot
      detail.merge!(invoice.setup_cbtes_asoc) unless invoice.cbtes_asoc_detail.nil?
      detail.merge!(invoice.setup_tributos) unless invoice.other_taxes.zero? || invoice.other_taxes_detail.nil?
      detail.merge!(invoice.setup_iva) unless invoice.net.zero? || invoice.iva_detail.nil?
    end

    # Validates that invoice attributes are correct when converting it to AFIP Hash
    # return [Boolean] if all validations passes
    #
    def validate_invoice_attrs
      validate_total
      validate_document_number
      validate_document_type
      validate_concept
    end

    # Generates the IVA Hash for each iva aliquot passed in the invoice object
    #
    # The Iva Hash MUST be an array in this format.
    # [ {'Id' => 2, 'BaseImp' => 2331.3, 'Importe' => 234.2 },
    # { 'Id' => 1, 'BaseImp' => 2331.3, 'Importe' => 234.2 } ]
    #
    # @return [Hash]
    #
    def setup_iva
      return nil if net.zero?

      iva_hash = {}
      iva_hash['Iva'] = []
      iva_detail.each do |iva_aliquot|
        iva_hash['Iva'] << { 'AlicIva' => iva_aliquot }
      end
      iva_hash
    end

    # Generates the "Tributos" Hash for each tributo aliquot passed in the invoice object
    #
    # The Tributos Hash MUST be an array in this format.
    # [ {'Id' => 2, 'Desc' => 'Ingresos Brutos', BaseImp' => 2331.3, 'Alic' => 3, Importe' => 234.2 },
    # {'Id' => 2, 'Desc' => 'Ingresos Brutos', BaseImp' => 2331.3, 'Alic' => 3, Importe' => 234.2 } ]
    #
    # @return [Hash]
    #
    def setup_tributos
      return nil if other_taxes.zero?

      tributos_hash = {}
      tributos_hash['Tributos'] = []
      other_taxes_detail.each do |other_tax|
        tributos_hash['Tributos'] << { 'Tributo' => other_tax }
      end
      tributos_hash
    end

    # Generates the "CbtesAsoc" Hash for each CbteAsoc  passed in the invoice object
    #
    # The Tributos Hash MUST be an array in this format.
    # [ {'Tipo' => 2, 'PtoVta' => '1, 'Nro' => 2333 },
    # {'Tipo' => 2, 'PtoVta' => '1, 'Nro' => 2333 } ]
    #
    # @return [Hash]
    #
    def setup_cbtes_asoc
      return nil if cbtes_asoc_detail.empty?

      cbtes_asoc_hash = {}
      cbtes_asoc_hash['CbtesAsoc'] = []
      cbtes_asoc_detail.each do |cbte_asoc|
        cbtes_asoc_hash['CbtesAsoc'] << { 'CbteAsoc' => cbte_asoc }
      end
      cbtes_asoc_hash
    end

    # Validates that the total is exactly the sum of all concepts
    def validate_total
      return true unless @total != @net + @exempt + @iva + @other_taxes

      raise Error.new, 'el importe total no coincide con la suma de todos los conceptos monetarios'
    end

    def validate_document_number
      return true unless document_number.nil?

      raise Error.new, 'el numero de documento del comprador es obligaroio'
    end

    def validate_document_type
      return true if VALID_DOCUMENT_TYPES.include?(document_type)

      raise Error.new, 'el tipo de documento informado es invalido'
    end

    def validate_concept
      return true if VALID_CONCEPTS.include?(afip_concept)

      raise Error.new, 'el concepto afip informado es invalido'
    end

    # <------------------- END INVOICE CLASS -------------------> #
  end
  # <------------------- END MODULE -------------------> #
end
