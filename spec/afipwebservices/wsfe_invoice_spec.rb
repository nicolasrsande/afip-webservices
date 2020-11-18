require 'spec_helper'

module AfipWebservices
  RSpec.describe WSFEInvoice do
    one_cbte = {
      document_type: 80,
      document_number: 20930280306,
      net: 2243.4,
      iva: 471.11,
      total: 2714.51,
      iva_detail: [{ 'Id' => 5, 'BaseImp' => 2243.4, 'Importe' => 471.11 },
                   { 'Id' => 5, 'BaseImp' => 2243.4, 'Importe' => 471.11 }]
    }
    

  end
end
