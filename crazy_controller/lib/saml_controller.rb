class SamlController < DummyController
  attr_reader :saml_destination_path, :response, :identity_provider, :identity_creator

  def create
    @identity_creator = SamlIdentityCreator.new(self, params[:idp], params[:SAMLResponse])

    log_in_as identity_creator.account

    if identity_creator.test_mode?
      @saml_destination_path = redirect_path
      @validation_errors     = identity_creator.response_errors
      return render 'test_interstitial'
    end

    if identity_creator.invalid_response?
      return redirect_to root_path
    end

    if identity_creator.has_saml_account?
      return redirect_to redirect_path
    end

    if identity_creator.has_saml_consumer_application?
      session[ConsumerApplication::SESSION_KEY] = identity_creator.consumer_application_as_param
      return redirect_to redirect_path
    end

    session[:saml_attributes]  = identity_creator.translated_response_attributes
    session[:saml_identity_id] = identity_creator.identity_as_param
    redirect_to identity_creator.deployment_shortcode_path
  end

end