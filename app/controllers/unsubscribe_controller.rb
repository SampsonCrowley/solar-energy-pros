# encoding: utf-8
# frozen_string_literal: true

class UnsubscribeController < ApplicationController
  # == Modules ============================================================

  # == Class Methods ======================================================

  # == Pre/Post Flight Checks =============================================

  # == Actions ============================================================
  def post
    @success = unsubscribe_email(params[:email], CoerceBoolean.from(params[:all].presence, strict: true))

    return render :show, status: @success ? 200 : 422
  end

  # == Cleanup ============================================================

  # == Utilities ==========================================================
  private
    def unsubscribe_email(email, all)
      raise StandardError.new "email is required" unless email.present?

      unsubscriber = Unscriber.find_by(email: email.presence) ||
                     Unscriber.new(email: email.presence, all: all)

      if unsubscriber.persisted?
        unsubscriber.update(all: true) if all && !unsubscriber.all
      else
        unsubscriber.save
      end

      if unsubscriber.persisted?
        true
      else
        @errors = unsubscriber.errors.full_messages
        false
      end
    rescue
      @errors = [ "No email given" ]
      false
    end

end
