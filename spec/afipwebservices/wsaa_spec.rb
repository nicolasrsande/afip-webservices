require 'spec_helper'

module AfipWebservices

  RSpec.describe WSAA do

    wsaa_test = AfipWebservices::WSAA.new
    key = 'spec/fixtures/certs/pkey'
    cert = 'spec/fixtures/certs/cert.crt'
    service = 'wsfe'

    context 'Tra Generation' do
      it 'expect to return the generated TRA XML' do
        xml = wsaa_test.build_tra('wsfe')
        puts 'Check Manually: ' + xml  #TODO: Check the xml
      end
    end

    context 'Tra Sign' do
      it 'should sign the cert and pkey' do
        tra = wsaa_test.tra(key, cert, service)
        expect(wsaa_test.sign_tra(tra, key, cert).to_s) =~ /BEGIN PKCS7/
      end
    end

    context 'Tra Codify' do
      it 'should delete header and footer' do
        expect(wsaa_test.codify_tra(OpenSSL::PKCS7.new)).not_to include('BEGIN', 'END')
      end
    end

    context 'Login' do
      it 'should send the tra to the webservice and return the TA' do
        ws = WSAA.new key: 'key', cert: 'cert'
        ws.expects(:tra).with('key', 'cert', 'wsfe', 2400).returns('tra')
        savon.expects(:login_cms).with(message: {in0: 'tra'}).returns(fixture('wsaa/login_cms/success'))
        ta = ws.login
        ta[:token].should == 'PD94='
        ta[:sign].should == 'i9xDN='
        ta[:generation_time].should == Time.new(2011, 1, 12, 18, 57, 4, '-03:00')
        ta[:expiration_time].should == Time.new(2011, 1, 13, 6, 57, 4, '-03:00')
      end
    end

    context 'Auth' do
      before do
        FileUtils.rm_rf Dir.glob('tmp/*-test-*-ta.dump')
      end
      
      it 'must contain token and sign fetched from afip' do
        ws = WSAA.new
        ws.expects(:login).once.returns(token: 'token', sign: 'sign', expiration_time: Time.now + 60)
        ws.auth.should == {token: 'token', sign: 'sign'}
      end
      
      it 'must cache the ta en on the instance and disk' do

      end
      it 'if the ta expired. it must do another login and return a new one' do

      end
    end
  end
end

