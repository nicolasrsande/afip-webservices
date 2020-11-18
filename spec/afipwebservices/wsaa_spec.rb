require 'spec_helper'

module AfipWebservices

  RSpec.describe WSAA do

    key = 'spec/fixtures/certs/pkey'
    cert = 'spec/fixtures/certs/cert.crt'
    service = 'wsfe'

    context '.build_tra - building the tra xml' do
      ws = WSAA.new.build_tra('wsfe')
      puts ws #TODO:
    end

    context 'codify and sign the tra' do
      ws =  WSAA.new.tra(key, cert, service)
      puts ws #TODO:
    end

    context 'login to WSAA webservice' do
      it 'should send the builded and signed tra to the webservice and return the TA' do
        ws = WSAA.new(key: 'key', cert: 'cert')
        expect(ws.tra(key, cert, service)).returns('tra')
        savon.expects(:login_cms).with(message: {in0: 'tra'}).returns(fixture('wsaa/login_cms/success'))
        ta = ws.login
        ta[:token].should == 'PD94='
        ta[:sign].should == 'i9xDN='
        ta[:generation_time].should == Time.new(2011, 1, 12, 18, 57, 4, '-03:00')
        ta[:expiration_time].should == Time.new(2011, 1, 13, 6, 57, 4, '-03:00')
      end
    end

    context 'Auth' do
      it 'should contain the token and sign of WSAA auth' do
        ws = WSAA.new
        ws.expects(:login).once.returns(token: 'token', sign: 'sign', expiration_time: Time.now + 60)
        ws.auth.should == { token: 'token', sign: 'sign' }
      end
    end

    context 'persisting and restoring the ta' do

    end

  end
end

