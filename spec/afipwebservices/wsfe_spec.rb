require 'spec_helper'

module AfipWebservices
  RSpec.describe WSFE do

    one_cbte = {
        document_type: 80,
        document_number: 20930280306,
        net: 2243.40,
        iva: 471.11,
        total: 2714.51,
        iva_detail: [{ 'Id' => 5, 'BaseImp' => 2243.4, 'Importe' => 471.11 }]
    }

    context 'Solicitar CAE Auth: ' do
      it 'generates the XML request for 1 cbte send it to AFIP' do
        ws = WSFE.new(cbte_type: 6, cbte_pto_venta: 1)
        invoice = WSFEInvoice.new(one_cbte)
        ws.add_new_invoice(invoice)
        ws.authorize
        puts ws
      end

    end

    context 'Authentication' do

    end

    context 'ENV Responses' do

    end

    context 'Validations and Errors' do

    end

  end
end


