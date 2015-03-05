require 'spec_helper'

describe SamlController, 'GET #new' do
  let(:idp) { :local }
  let(:saml_params) { Rack::Utils.parse_query URI(response.redirect_url).query }

  subject { get :new, idp: idp }

  context 'without an idp parameter' do
    subject { get :new }

    it 'returns 404' do
      expect { subject }.to raise_error ActionController::RoutingError
    end
  end

  context 'with a OneLogin idp parameter' do
    let(:idp) { :onelogin }

    it 'passes SAML request' do
      subject
      saml_params['SAMLRequest'].should be_present
    end

    it 'redirects to OneLogin' do
      subject
      response.should be_redirect
      response.redirect_url.starts_with? 'https://app.onelogin.com/saml/metadata/221064'
    end
  end

  context 'with an unknown IDP' do
    let(:idp) { :unknown_idp }

    it 'raises an exception' do
      expect { subject }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end

describe SamlController, '#POST create' do
  let(:deployment) { deployments(:test_deployment) }
  let(:idp_response) { open(Rails.root.join('testdata', 'saml', 'idp_response.xml'), 'rb') { |io| io.read } }
  let(:account) { accounts(:participant) }
  let(:email) { account.email }
  let(:idp_issuer) { 'OmadaHealthLocalSAMLIdentityProvider' }

  subject { post :create, SAMLResponse: idp_response }

  before { idp_response.gsub! '$$EMAIL$$', email }
  before { idp_response.gsub! '$$IDP_ISSUER$$', idp_issuer }

  context 'with an unknown IDP' do
    let(:idp_issuer) { 'BogoSAMLIdentityProvider' }

    it 'raises an exception' do
      expect { subject }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'with an invalid response' do
    before do
      Onelogin::Saml::Response.any_instance.stub(:is_valid?).and_return(false)
    end

    it 'should redirect to the root_path' do
      subject
      response.should redirect_to root_path
    end
  end

  context 'with a valid response' do
    before { Onelogin::Saml::Response.any_instance.stub(:is_valid?).and_return(true) }

    context 'when test mode is on' do
      before do
        idp = SamlIdentityProvider.find_by_issuer(idp_issuer)
        idp.test_mode = true
        idp.save!
      end

      it 'shows the test interstitial' do
        subject
        expect{ response }.to render_template 'test_interstitial'
      end

      it 'assigns the redirect path' do
        subject
        expect(assigns[:saml_destination_path]).to eq redirect_path
      end
    end

    context 'when test mode is off' do
      it 'redirects to the redirect_path' do
        subject
        expect{ response }.to redirect_to redirect_path
      end
    end

    context 'for a visitor without a SAML identity' do
      let(:email) { 'userWeHaveNeverSeenBefore@example.com' }

      context 'for a new applicant' do
        subject { post :create, SAMLResponse: idp_response }

        it 'creates a SAML identity' do
          expect{ subject }.to change{ SamlIdentity.count }.by 1
        end

        it 'stores response attributes in the session for later usage' do
          subject
          attributes = session[:saml_attributes]
          expect(attributes[:first_name]).to eq('Terry')
          expect(attributes[:last_name]).to eq('Bradshaw')
          expect(attributes[:email]).to eq('userWeHaveNeverSeenBefore@example.com')
          expect(attributes[:phone_number]).to eq('867-5309')
          expect(attributes[:zip_code]).to eq('12345')
        end

        it 'stores the SAML identity id in the session' do
          subject
          expect(session[:saml_identity_id]).to be_present
        end

        it 'redirects to the deployment-specific show page' do
          subject
          expect{ response }.to redirect_to deployment_shortcode_path(deployment.code)
        end
      end

      context 'when there is already a consumer application for this email address' do
        let(:consumer_application) { account.consumer_application }

        before { consumer_application.update_attributes!(email: email) }

        it 'does not store the consumer application id in the session' do
          subject
          expect(session[ConsumerApplication::SESSION_KEY]).to_not be_present
        end
      end
    end

    context 'for a visitor with a SAML identity' do

      context 'who does not have a consumer application' do
        let(:identity) { saml_identities(:local_saml_identity) }
        let(:email) { identity.name_id }

        it 'does not create a SAML identity' do
          expect{ subject }.to_not change(SamlIdentity, :count)
        end

        it 'stores response attributes in the session for later usage' do
          subject
          expect(session[:saml_attributes]).to be_present
        end

        it 'stores the SAML identity id in the session' do
          subject
          expect(session[:saml_identity_id]).to be_present
        end

        it 'redirects to the deployment-specific show page' do
          subject
          expect{ response }.to redirect_to deployment_shortcode_path(deployment.code)
        end
      end

      context 'who has an un-submitted consumer application' do
        let(:identity) { saml_identities(:with_step2_application) }
        let(:consumer_application) { identity.consumer_application }
        let(:email) { identity.name_id }

        it 'sets the session consumer_application_id for this application' do
          subject
          expect(session[:consumer_application_id]).to eq consumer_application.to_param
        end

        it 'redirects them to the appropriate page' do
          subject
          expect{ response }.to redirect_to redirect_path
        end
      end

      context 'who has a submitted application' do
        let(:identity) { saml_identities(:with_submitted_application) }
        let(:consumer_application) { identity.consumer_application }
        let(:email) { identity.name_id }

        it 'sets the session consumer_application_id for this application' do
          subject
          expect(session[:consumer_application_id]).to eq consumer_application.to_param
        end

        it 'redirects them to the appropriate page' do
          subject
          expect{ response }.to redirect_to redirect_path
        end
      end
    end

    context 'for an existing user with a SAML identity' do
      it 'should log them in' do
        subject
        session[:account_id].should == account.id
      end

      it 'redirects to redirect_path' do
        subject
        expect{ response }.to redirect_to redirect_path
      end
    end
  end
end
