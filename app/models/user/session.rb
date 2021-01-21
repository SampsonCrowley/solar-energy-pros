# encoding: utf-8
# frozen_string_literal: true

# User::Session description
class User < Person
  class Session < ApplicationRecord
    # == Constants ============================================================

    # == Attributes ===========================================================
    self.table_name = "user_session"
    nacl_password :token, skip_validations: true

    # == Extensions ===========================================================

    # == Attachments ==========================================================

    # == Relationships ========================================================
    belongs_to :user,
      required:   true,
      inverse_of: :sessions

    # == Validations ==========================================================

    # == Scopes ===============================================================

    # == Callbacks ============================================================

    # == Boolean Class Methods ================================================

    # == Class Methods ========================================================
    def self.create_token
      RbNaCl::Random.random_bytes(64)
    end

    def self.create_encoded_token
      encode_token create_token
    end

    def self.encode_token(bytes)
      RbNaCl::Util.bin2hex(bytes)
    end

    def self.decode_token(hex)
      RbNaCl::Util.hex2bin(hex)
    end

    # == Boolean Methods ======================================================
    def allowed?(token_password = nil)
      (updated_at > 24.hours.ago) &&
      !!authenticate_token(token_password || current_token)
    end

    # == Instance Methods =====================================================

    # == Private Methods ======================================================
    private
      def current_token
        Current.browser_token.presence \
        || self.class.create_token
      end

  end
end
