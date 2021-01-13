# encoding: utf-8
# frozen_string_literal: true

# Unsubscriber description
class Unsubscriber < ApplicationRecord
  # == Constants ============================================================

  # == Attributes ===========================================================
  attribute :call, :text
  attribute :email, :text
  attribute :mail, :text
  attribute :text, :text

  # == Extensions ===========================================================

  # == Attachments ==========================================================

  # == Relationships ========================================================

  # == Validations ==========================================================
  validates_uniqueness_of_scope :value, :category,
    attribute: :value,
    message: "already exists"

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  # == Boolean Class Methods ================================================

  # == Class Methods ========================================================
  def self.find_by(param, *arg)
    super(convert_params(param, types: true), *arg)
  end

  def self.convert_params(params, types: false)
    if params.is_a? Hash
      params = params.deep_symbolize_keys
      if types
        %i[ call email mail text ].each do |a|
          v = params.delete a
          if v.present?
            params[:category] = a
            params[:value] = v
            break
          end
        end
      end

      if params[:category].present?
        params[:category] = UnsubscriberCategory.convert_to_unsubscriber_category(params[:category])
        if params[:value].present?
          params[:value] = format_for_category(params[:value], params[:category])
        end
      end
      super params
    else
      params
    end
  end

  def self.format_for_category(value, category = "E")
    if value.is_a?(Array)
      value.map {|v| format_for_category(v, category)}.flatten
    else
      case category.to_sym
      when :E
        value.to_s.downcase.split(";").map(&:strip)
      when :M
        value.to_s.downcase.gsub(/\n/, ", ")
      when :T, :C
        value.to_s.gsub(/[^0-9]/, "")
      end
    end
  end

  # == Boolean Methods ======================================================

  # == Instance Methods =====================================================
  def parsed_category
    self.category = self[:category] unless self[:category].to_s =~ /^[A-Z]$/
    self[:category]
  end

  def category=(cat)
    self[:category] = UnsubscriberCategory.convert_to_unsubscriber_category(cat)
  end

  def call
    parsed_category == "C" ? self.value : nil
  end

  def call=(call_val)
    self.category = "C"
    self.value = value.to_s.gsub(/[^0-9]/, "")
  end

  def email
    parsed_category == "E" ? self.value : nil
  end

  def email=(email_val)
    self.category = "E"
    self.value = email_val.to_s.presence&.strip&.downcase
  end

  def mail
    parsed_category == "M" ? self.value : nil
  end

  def mail=(mail_val)
    self.category = "M"
    self.value = mail_val.to_s.presence&.strip&.downcase
  end

  def text
    parsed_category == "T" ? self.value : nil
  end

  def text=(text_val)
    self.category = "T"
    self.value = value.to_s.gsub(/[^0-9]/, "")
  end

  # == Private Methods ======================================================

end
