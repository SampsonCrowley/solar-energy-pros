# encoding: utf-8
# frozen_string_literal: true

# User description
class Person < ApplicationRecord
  # == Constants ============================================================
  PASSWORD_COLUMNS =
    %w[ password_digest single_use_digest single_use_expires_at ].freeze



  # == Extensions ===========================================================
  include LiberalEnum

  # == Attributes ===========================================================
  has_logidze

  attr_readonly *PASSWORD_COLUMNS

  # == Attachments ==========================================================
  has_one_attached :avatar

  # == Relationships ========================================================
  has_many :backgrounds, inverse_of: :person

  # == Validations ==========================================================
  validates_presence_of :first_names, :last_names

  validates_uniqueness_of :email,
    allow_blank:  true,
    if:           :email_needs_validation?

  validates_presence_of :email,
    message:  "required for login",
    if:       :email_required?

  validates :email, email: true

  validates :avatar,
    blob: {
            type: /^image\/[a-z\-._+]+$/i,
            size: 0..2.megabytes,
            allow_blank: true
          }

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  # == Boolean Class Methods ================================================

  # == Class Methods ========================================================

  # == Boolean Methods ======================================================

  # == Instance Methods =====================================================
  def user
    self.becomes(User)
  end

  # == Private Methods ======================================================
  private
    def email_needs_validation?
      !self.persisted? || self.email_changed?
    end

    def email_required?
      self.password_digest.present?
    end

end
