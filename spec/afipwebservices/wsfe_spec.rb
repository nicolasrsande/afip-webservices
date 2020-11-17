require 'spec_helper'

module AfipWebservices
  RSpec.describe AfipWebservices::WSFE do

    context 'AFIP API Methods' do
      fe_dummy = AfipWebservices::WSFE.new.fe_dummy
      it 'returns a hash with afip statusses' do
        expect(fe_dummy).to include(:app_server, :db_server, :auth_server)
      end

      it 'expect all keys to be "OK" or there is a problem in AFIP services' do
        expect(fe_dummy[:app_server]).to eq 'OK'
        expect(fe_dummy[:db_server]).to eq 'OK'
        expect(fe_dummy[:auth_server]).to eq 'OK'
      end
    end

    context 'Send request and authorize cbtes - parse the responses' do
      it 'solicita el CAE de un comprobante' do
      
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


