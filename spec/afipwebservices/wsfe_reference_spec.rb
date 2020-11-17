require 'spec_helper'

module AfipWebservices
  RSpec.describe WSFEReference do
    describe 'get the last cbte authorized' do
      it 'must return last cbte number' do
        request = WSFE.new.last_cbte(pto_vta: 1, cbte_tipo: 6)
        puts request
        expect(request).to eq(434)
      end
    end
  end
end
