module AfipWebservices

  URLS = {
    test: { wsaa: 'https://wsaahomo.afip.gov.ar/ws/services/LoginCms?WSDL',
            wsfe: 'https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL' },
    production: { wsaa: 'https://wsaa.afip.gov.ar/ws/services/LoginCms?WSDL',
                  wsfe: 'https://servicios1.afip.gov.ar/wsfev1/service.asmx?WSDL' }
  }.freeze
  
  VALID_DOCUMENT_TYPES = [80, 86, 87, 89, 90, 91, 92, 93, 95, 96, 94, 99].freeze

  VALID_CONCEPTS = [1, 2, 3].freeze

  ## END CONSTANTS FILE ##
end
