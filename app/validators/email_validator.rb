require 'mail'

class EmailValidator < ActiveModel::EachValidator
  EMAIL_REGEX =
    /(^$|^[^@\s;.\/\[\]\\]+(\.[^@\s;.\/\[\]\\]+)*@[^@\s;.\/\[\]\\]+(\.[^@\s;.\/\[\]\\]+)*\.[^@\s;.\/\[\]\\]+$)/

  def validate_each(record, attribute, value)
    add_error(record, attribute) if value.present? && value !~ EMAIL_REGEX
  end

  private
    def add_error(record, attribute)
      record.errors.add(attribute, (options[:message] || "is not a valid address"))
    end
end
