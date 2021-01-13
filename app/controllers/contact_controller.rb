# encoding: utf-8
# frozen_string_literal: true

class ContactController < ApplicationController
  # == Modules ============================================================
  REQUIRED_PARAMS = %i[
    name
    email
    street
    city
    zip
    estimated_electric_bill
    estimated_credit_score
  ]

  OPTIONAL_PARAMS = %i[
    phone
    message
  ]

  # == Class Methods ======================================================

  # == Pre/Post Flight Checks =============================================
  before_action :set_centered_grid

  # == Actions ============================================================

  # == Cleanup ============================================================

  # == Utilities ==========================================================
  def show
  end

  def create
    @success = validate_params

    send_contact_emails if @success

    return render action: :show, status: @success ? 200 : 422
  end

  private
    def set_centered_grid
      @grid_align = :middle
    end

    def whitelisted_params
      params.
        require(:contact).
        permit(*REQUIRED_PARAMS, *OPTIONAL_PARAMS)
    rescue
      {}
    end

    def validate_params
      REQUIRED_PARAMS.each do |param|
        push_error "#{t("contact.#{param}.label")} #{t(:required_field)}" unless whitelisted_params[param].present?
      end

      push_error t("contact.email.invalid") if bad_email?
      push_error t("contact.zip.invalid") if bad_zip?

      @errors.blank?
    rescue
      push_error "#{t("error.unknown")}: #{$!.message}"
      return false
    end

    def bad_email?
      whitelisted_params[:email].present? \
      && (whitelisted_params[:email] !~ EmailValidator::EMAIL_REGEX)
    end

    def bad_zip?
      whitelisted_params[:zip].present? \
      && (whitelisted_params[:zip] !~ ZipValidator::ZIP_REGEX)
    end

    def send_contact_emails
      data = whitelisted_params.merge(locale: determine_locale)
      ContactRequestMailer.with(data).received.deliver_later
      ContactRequestMailer.with(data).submission.deliver_later
    end

end
