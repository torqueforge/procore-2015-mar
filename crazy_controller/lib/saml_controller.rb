class SamlController < DummyController
  attr_reader :saml_destination_path, :response, :identity_provider

  def create
    @identity_provider = SamlIdentityProvider.for_name(params[:idp])

    @response =
      identity_provider.response(
        create_saml_url(deployment_code: identity_provider.deployment_code),
        params[:SAMLResponse])

    saml_identity = identity_provider.saml_identity_for_name_id(response.name_id)

    log_in_as saml_identity.account

    if !response.is_valid?
      target_path = root_path

    elsif saml_identity.account_id || saml_identity.consumer_application
      target_path = redirect_path

    elsif saml_identity.consumer_application
      session[ConsumerApplication::SESSION_KEY] = saml_identity.consumer_application.to_param

    else
      session[:saml_attributes]  = identity_provider.translated_attributes(response.attributes)
      session[:saml_identity_id] = saml_identity.to_param
      target_path = deployment_shortcode_path(identity_provider.deployment_code)
    end

    show_test_interstitial_or_redirect(target_path)
  end

private

  def show_test_interstitial_or_redirect(redirect_path)
    if identity_provider.test_mode?
      @saml_destination_path = redirect_path
      @validation_errors     = response_errors
      render 'test_interstitial'
    else
      redirect_to redirect_path
    end
  end

  def response_errors
    begin
      response.validate!
      nil
    rescue OneLoginSamlValidationError => e
      e.message
    end
  end

end