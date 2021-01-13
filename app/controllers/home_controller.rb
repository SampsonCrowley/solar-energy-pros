# encoding: utf-8
# frozen_string_literal: true

class HomeController < ApplicationController
  # == Modules ============================================================

  # == Class Methods ======================================================

  # == Pre/Post Flight Checks =============================================

  # == Actions ============================================================
  def show
  end

  def not_found
    @not_found = true
    return render :show
  end

  def detect_language
    locale = determine_locale
    redirect_to("/#{locale}#{request.env["PATH_INFO"]}")
  end

  # == Cleanup ============================================================

  # == Utilities ==========================================================

end
