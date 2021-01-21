module ActiveRecordPersisitenceOverrides
  warn "[DEPRECATED] #{self} should no longer be needed. Please remove!" if Rails.version >= "6.1.0"

  def self.prepended(base)
    base.class_eval do
      def becomes(klass)
        became = klass.allocate

        @attributes.slice!(*klass.attribute_names)

        klass.attribute_types.each do |k, type|
          unless @attributes.key?(k)
            @attributes[k] = ActiveModel::Attribute.with_cast_value(k, nil, type)
          end
        end

        became.send(:initialize) do |becoming|
          becoming.instance_variable_set(:@attributes, @attributes)
          becoming.instance_variable_set(:@mutations_from_database, @mutations_from_database ||= nil)
          becoming.instance_variable_set(:@new_record, new_record?)
          becoming.instance_variable_set(:@destroyed, destroyed?)
          becoming.errors.copy!(errors)
        end

        became
      end
    end
  end
end

ActiveRecord::Persistence.prepend ActiveRecordPersisitenceOverrides
