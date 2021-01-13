require 'mail'

class ZipValidator < ActiveModel::EachValidator
  ZIP_REGEX = /^[0-9]{4,5}(-[0-9]{4})?$/

  def validate_each(record, attribute, value)
    add_error(record, attribute) if value.present? && value !~ ZIP_REGEX
  end

  private
    def add_error(record, attribute)
      record.errors.add(attribute, (options[:message] || "is not a valid zip code."))
    end
end
