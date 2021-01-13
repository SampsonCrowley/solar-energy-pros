# encoding: utf-8
# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  helper EmailHelper
  include EmailHelper

  # after_action do
  #   sleep 8 unless CoerceBoolean.from(@async)
  # end

  default from: "Solar Energy Pros <info@solarenergypros.online>",
          content_transfer_encoding: "quoted-printable"

  layout 'mailer'

  def self.filter_emails(emails, all: false)
    all = all ? true : [ false, true, nil ]
    emails = [emails].flatten.map {|email| email.to_s.split(';').map {|e| e.strip.downcase}}
    emails = emails.flatten.uniq.select(&:present?)
    emails - Unsubscriber.where(category: 'E', value: emails, all: all).pluck(:value)
  end

  def mail(email: nil, skip_filter: false, **params)
    headers['List-Unsubscribe'] = '<mailto:unsubscribe@solarenergypros.online>'
    params.reverse_merge!(apply_defaults({}).slice(:use_account))


    use_account = params.delete(:use_account).presence
    mail_name = params.delete(:mail_name).presence || caller_locations(1,1)[0].label
    params[:to] = email if email

    has_email = false

    [:to, :cc, :bcc].each do |h|
      if params[h].present?
        params[h] = skip_filter ? production_email(params[h]) : filter_emails(params[h], all: true).presence
        has_email ||= params[h].present?
      end
    end

    params[:to] = production_email('no-email-available@solarenergypros.online') unless has_email

    if use_account &&= Rails.application.credentials.dig(:mailer, use_account, :from).presence
      params[:from] = use_account
    else
      params[:from] = "#{t(:title)} <info@solarenergypros.online>"
    end

    m = super(
      **params
    ) do |format|
      if block_given?
        yield format
      else
        format.text
        format.html(content_transfer_encoding: 'quoted-printable')
      end
    end
    m.content_transfer_encoding = 'quoted-printable'
    m
  end

  def money_email
    @money_email ||= production_email('money@solarenergypros.online')
  end

  def production_email(email = nil)
    if Rails.env.development?
      result = %w[ sampsonsprojects@gmail.com ]
    elsif block_given?
      result = yield
    else
      result = email
    end

    result
  end

  def filter_emails(emails, all: false)
    production_email do
      self.class.filter_emails(emails, all: all)
    end
  end

  def get_view
    av = ActionView::Base.new()
    av.view_paths = ActionController::Base.view_paths

    av.class_eval do
      include Rails.application.routes.url_helpers
      # include ApplicationHelper
    end
    av
  end

  def with_locale
    I18n.with_locale(params[:locale].presence || I18n.default_locale) do
      yield
    end
  end
end
