module AfipWebservices
  # rubocop:disable Metrics/LineLength
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
      @issue_date = params[:issue_date]
      @due_date = params[:due_date]
      @date_from = params[:date_from]
      @date_to = params[:date_to]
      @document_type = params[:document_type]
      @document_number = params[:document_number]
      @cbte_number = params[cbte_number]
      @net = params[:net].to_f.round(2) || 0.00
      @exempt = params[:exempt].to_f.round(2) || 0.00
      @iva = params[:iva].to_f.round(2) || 0.00
      @other_taxes = params[:other_taxes].to_f.round(2) || 0.00
      @total = params[:total]
      @currency = params[:currency]
      @currency_cot = params[:currency_cot]
      @afip_concept = params[:afip_concept]

      # Arrays for taxes and associations:
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
    def self.setup_invoice(invoice, cbte)
      detail = {}
      detail['Concepto']      = invoice.afip_concept || '03' # Default to "Productos y Servicios"
      detail['DocTipo']       = invoice.document_type || '80' # Default to "CUIT" if not informed
      detail['DocNro']        = invoice.document_number
      detail['CbteDesde']     = detail['CbteHasta'] = invoice.cbte_number || cbte
      detail['CbteFch']       = parse_date(invoice.issue_date) || today
      detail['ImpTotal']      = invoice.total
      detail['ImpTotConc']    = 0.00 # TODO: What it is this field? Default 0
      detail['ImpNeto']       = invoice.net || 0.00
      detail['ImpOpEx']       = invoice.exempt || 0.00
      detail['ImpTrib']       = invoice.other_taxes || 0.00
      detail['ImpIVA']        = invoice.iva || 0.00
      detail['FchServDesde']  = parse_date(invoice.date_from) || today
      detail['FchServHasta']  = parse_date(invoice.date_to) || today
      detail['FchVtoPago']    = parse_date(invoice.due_date) || today
      detail['MonId']         = invoice.currency || 'PES' # Default: "Pesos"
      detail['MonCotiz']      = invoice.currency_cot || 1 # Default: 1

      # Merge CbtesAsoc Hash to the Detail
      detail.merge!(setup_cbtes_asoc(invoice)) unless invoice.cbtes_asoc_detail.empty?

      # Merge Tributos Hash to the Detail
      detail.merge!(setup_tributos(invoice)) unless invoice.net.zero? || invoice.iva_detail.empty?

      # Merge IVA Hash to the Detail
      detail.merge!(setup_iva(invoice)) unless invoice.other_taxes.zero? || invoice.other_taxes_detail.empty?
    end

    # <------------------- PRIVATE METHODS -------------------> #
    private

    # Generates the IVA Hash for each iva aliquot passed in the invoice object
    #
    # The Iva Hash MUST be an array in this format.
    # [ {'Id' => 2, 'BaseImp' => 2331.3, 'Importe' => 234.2 },
    # { 'Id' => 1, 'BaseImp' => 2331.3, 'Importe' => 234.2 } ]
    #
    # @return [Hash]
    #
    def setup_iva(invoice)
      return nil if invoice.net.zero?

      iva = {}
      invoice.iva_detail.each do |alic_iva|
        iva['Iva'] << { 'AlicIva' => alic_iva }
      end
      iva
    end

    # Generates the "Tributos" Hash for each tributo aliquot passed in the invoice object
    #
    # The Tributos Hash MUST be an array in this format.
    # [ {'Id' => 2, 'Desc' => 'Ingresos Brutos', BaseImp' => 2331.3, 'Alic' => 3, Importe' => 234.2 },
    # {'Id' => 2, 'Desc' => 'Ingresos Brutos', BaseImp' => 2331.3, 'Alic' => 3, Importe' => 234.2 } ]
    #
    # @return [Hash]
    #
    def setup_tributos(invoice)
      return nil if invoice.other_taxes.zero?

      otros_tributos = {}
      invoice.other_taxes_detail.each do |other_tax|
        otros_tributos['Tributos'] << { 'Tributo' => other_tax }
      end
      otros_tributos
    end

    # Generates the "CbtesAsoc" Hash for each CbteAsoc  passed in the invoice object
    #
    # The Tributos Hash MUST be an array in this format.
    # [ {'Tipo' => 2, 'PtoVta' => '1, 'Nro' => 2333 },
    # {'Tipo' => 2, 'PtoVta' => '1, 'Nro' => 2333 } ]
    #
    # @return [Hash]
    #
    def setup_cbtes_asoc(invoice)
      return nil if invoice.cbtes_asoc_detail.empty?

      cbtes_asoc = {}
      invoice.cbtes_asoc_detail.each do |cbte|
        cbtes_asoc['CbtesAsoc'] << { 'CbteAsoc' => cbte }
      end
      cbtes_asoc
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

    # Validates that the total is exactly the sum of all concepts
    def validate_total
      true unless @total != @net + @exempt + @iva + @other_taxes
      raise Error.new, 'el importe total no coincide con la suma de todos los conceptos monetarios'
    end

    def validate_document_number
      true unless document_number.nil?
      raise Error.new, 'el numero de documento del comprador es obligaroio'
    end

    def validate_document_type
      true unless document_type.not.included(VALID_DOCUMENT_TYPES)
      raise Error.new, 'el tipo de documento informado es invalido'
    end

    def validate_concept
      true unless afip_concept.not.included(VALID_CONCEPTS)
      raise Error.new, 'el concepto afip informado es invalido'
    end

    # <------------------- END INVOICE CLASS -------------------> #
  end
  # <------------------- END MODULE -------------------> #
end
