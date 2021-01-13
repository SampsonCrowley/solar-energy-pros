class ApplicationController < ActionController::Base
  # == Modules ============================================================
  include Authenticated
  helper GridHelper
  helper SelectMenuHelper
  helper WebpackerOverrides

  # == Class Methods ======================================================

  # == Pre/Post Flight Checks =============================================

  # == Actions ============================================================

  # == Cleanup ============================================================
  around_action :switch_locale


  # == Utilities ==========================================================
  private
    def push_error(msg)
      @errors = [] if @errors.nil?
      @errors << msg
      @errors
    end

    def switch_locale(&action)
      I18n.with_locale(determine_locale, &action)
    end

    def determine_locale
      params[:locale] \
      || http_accept_language.compatible_language_from(I18n.available_locales) \
      || I18n.default_locale
    end

    def default_url_options
      { locale: I18n.locale }
    end
end
