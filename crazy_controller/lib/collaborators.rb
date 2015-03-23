require 'pry'

class SamlIdentityCreator
  attr_reader :controller, :identity_provider, :saml_response_param,
              :identity, :response,
              :response_class, :saml_settings

  def initialize(controller, idp_param, saml_response_param)
    @controller          = controller
    @saml_response_param = saml_response_param

    @identity_provider   = SamlIdentityProvider.for_name(idp_param)
    @saml_settings       = OneLoginSamlSettings.new

    @response_class      = determine_response_class
    @response            = build_response
    @identity            = retrieve_identity
  end

  def account
    identity.account
  end


  #################### response
  def build_response
    saml_settings.assertion_consumer_service_url = saml_url
    saml_settings.issuer                         = identity_provider.issuer
    saml_settings.idp_sso_target_url             = identity_provider.target_url
    saml_settings.idp_cert_fingerprint           = identity_provider.fingerprint

    response = response_class.new(saml_response_param)

    response.settings = saml_settings
    response
  end

  def validate_response!
  end

  def response_errors
    begin
      validate_response!
      nil
    rescue OneLoginSamlValidationError => e
      e.message
    end
  end


  ###################
  def retrieve_identity
    identity_provider.saml_identity_for_name_id(response.name_id)
  end

  def determine_response_class
    if identity_provider.issuer == 'www.healthnet.com:omada'
      HealthNetSamlResponse
    else
      StandardResponse
    end
  end


  #################### ontroller is responsible for urls and paths
  def saml_url
    controller.create_saml_url(deployment_code: identity_provider.deployment_code)
  end

  def deployment_shortcode_path
    controller.deployment_shortcode_path(identity_provider.deployment_code)
  end


  ###################
  def test_mode?
    identity_provider.test_mode?
  end

  def should_process_as_existing_saml?
    has_saml_account? || has_saml_consumer_application?
  end

  def has_saml_account?
    identity.account_id
  end

  def has_saml_consumer_application?
    identity.consumer_application
  end

  def valid_response?
    true
  end

  def invalid_response?
    !valid_response?
  end


  #################### conversions
  def identity_as_param
    identity.to_param
  end

  def consumer_application_as_param
    identity.consumer_application.to_param
  end

  def translated_response_attributes
    identity_provider.translated_attributes(response.attributes)
  end
end

class ConsumerApplication
  SESSION_KEY = nil
end

class SamlIdentityProvider
  def self.for_name(name)
    raise ActiveRecord::RecordNotFound if name == 'BogoSAMLIdentityProvider'
    return SamlIdentityProvider.new
  end

  def self.where(hsh)
    raise ActiveRecord::RecordNotFound if hsh[:name] == 'BogoSAMLIdentityProvider'
    return [SamlIdentityProvider.new]
  end

  def deployment_code
    'a deployment_code'
  end

  def issuer
  end

  def target_url
  end

  def fingerprint
  end

  def test_mode?
    false
  end

  def saml_identity_for_name_id(id)
    return SamlIdentity.new(nil, 'new account') unless id
    return SamlIdentity.new
  end

  def translated_attributes(attrs)
    attrs
  end

end

class SamlIdentity

  attr_reader :account_id, :account
  def initialize(account_id=1,account='an account')
    @account_id = account_id
    @account    = account
  end

  def consumer_application
  end

  def to_param
    return 1 if account == 'an account'
    return 2 if account == 'new account'
  end
end

class OneLoginSamlSettings
  attr_reader :assertion_consumer_service_url, :issuer, :idp_sso_target_url, :idp_cert_fingerprint

  def assertion_consumer_service_url=(arg)
    @assertion_consumer_service_url = arg
  end

  def issuer=(arg)
    @issuer = arg
  end

  def idp_sso_target_url=(arg)
    @idp_sso_target_url = arg
  end

  def idp_cert_fingerprint=(arg)
    @idp_cert_fingerprint = arg
  end
end

class OneLoginSamlValidationError
end

module ActiveRecord
  class RecordNotFound < Exception
  end
end

class StandardResponse
  attr_reader :settings, :saml_response

  def initialize(saml_response)
    @saml_response = saml_response
  end

  def settings=(data)
     @settings = data
  end

  def name_id
    saml_response[:name_id]
  end

  def is_valid?
    true
  end

  def validate!
  end

  # def issuer
  # end

  def attributes
    saml_response
  end
end

class HealthNetSamlResponse < StandardResponse
end

class DummyController
  attr_reader :params, :session
    # params[:SAMLResponse]
    # params[:idp]
    # session[ConsumerApplication::SESSION_KEY]
    # session[:saml_attributes]
    # session[:saml_identity_id]

  def initialize
    @params  = {}
    @session = {}
  end

  def render(thing)
  end

  def redirect_to(path)
    "redirected to #{path}"
  end

  def redirect_path
    "this/is/the/redirect/path"
  end

  def root_path
    "this/is/the/root/path"
  end

  def deployment_shortcode_path(path)
    "deployment/shortcode/for/#{path}"
  end

  def log_in_as(account)
  end

  def create_saml_url(deployment_code)
  end
end