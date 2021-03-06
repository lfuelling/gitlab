# frozen_string_literal: true

module SpammableActions
  extend ActiveSupport::Concern

  include Recaptcha::Verify
  include Gitlab::Utils::StrongMemoize

  included do
    before_action :authorize_submit_spammable!, only: :mark_as_spam
  end

  def mark_as_spam
    if Spam::MarkAsSpamService.new(target: spammable).execute
      redirect_to spammable_path, notice: _("%{spammable_titlecase} was submitted to Akismet successfully.") % { spammable_titlecase: spammable.spammable_entity_type.titlecase }
    else
      redirect_to spammable_path, alert: _('Error with Akismet. Please check the logs for more info.')
    end
  end

  private

  def ensure_spam_config_loaded!
    strong_memoize(:spam_config_loaded) do
      Gitlab::Recaptcha.load_configurations!
    end
  end

  def recaptcha_check_with_fallback(should_redirect = true, &fallback)
    if should_redirect && spammable.valid?
      redirect_to spammable_path
    elsif render_recaptcha?
      ensure_spam_config_loaded!

      respond_to do |format|
        format.html do
          render :verify
        end

        format.json do
          locals = { spammable: spammable, script: false, has_submit: false }
          recaptcha_html = render_to_string(partial: 'shared/recaptcha_form', formats: :html, locals: locals)

          render json: { recaptcha_html: recaptcha_html }
        end
      end
    else
      yield
    end
  end

  def spammable_params
    default_params = { request: request }

    recaptcha_check = recaptcha_response &&
      ensure_spam_config_loaded! &&
      verify_recaptcha(response: recaptcha_response)

    return default_params unless recaptcha_check

    { recaptcha_verified: true,
      spam_log_id: params[:spam_log_id] }.merge(default_params)
  end

  def recaptcha_response
    # NOTE: This field name comes from `Recaptcha::ClientHelper#recaptcha_tags` in the recaptcha
    # gem, which is called from the HAML `_recaptcha_form.html.haml` form.
    #
    # It is used in the `Recaptcha::Verify#verify_recaptcha` if the `response` option is not
    # passed explicitly.
    #
    # Instead of relying on this behavior, we are extracting and passing it explicitly. This will
    # make it consistent with the newer, modern reCAPTCHA verification process as it will be
    # implemented via the GraphQL API and in Vue components via the native reCAPTCHA Javascript API,
    # which requires that the recaptcha response param be obtained and passed explicitly.
    #
    # After this newer GraphQL/JS API process is fully supported by the backend, we can remove this
    # (and other) HAML-specific support.
    params['g-recaptcha-response']
  end

  def spammable
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def spammable_path
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def authorize_submit_spammable!
    access_denied! unless current_user.admin?
  end

  def render_recaptcha?
    return false if spammable.errors.count > 1 # re-render "new" template in case there are other errors
    return false unless Gitlab::Recaptcha.enabled?

    spammable.needs_recaptcha?
  end
end
