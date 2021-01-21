require "active_support/core_ext/enumerable"

module ActiveModelAttributeOverrides
  warn "[DEPRECATED] #{self} should no longer be needed. Please remove!" if Rails.version >= "6.1.0"

  module AttributeOverrides
    def self.prepended(base)
      base.class_eval do
        class << self
          def from_database(name, value_before_type_cast, type, value = nil)
            self.const_get(:FromDatabase).new(name, value_before_type_cast, type, nil, value)
          end

          def from_user(name, value_before_type_cast, type, original_attribute = nil)
            self.const_get(:FromUser).new(name, value_before_type_cast, type, original_attribute)
          end

          def with_cast_value(name, value_before_type_cast, type)
            self.const_get(:WithCastValue).new(name, value_before_type_cast, type)
          end
        end

        # This method should not be called directly.
        # Use #from_database or #from_user
        def initialize(name, value_before_type_cast, type, original_attribute = nil, value = nil)
          @name = name
          @value_before_type_cast = value_before_type_cast
          @type = type
          @original_attribute = original_attribute
          @value = value unless value.nil?
        end

        protected :original_value_for_database
      end
    end
  end

  module AttributeSetOverrides # :nodoc:
    def self.prepended(base)
      base.class_eval do
        def [](name)
          @attributes[name] || default_attribute(name)
        end

        def to_hash
          keys.index_with { |name| self[name].value }
        end
        alias :to_h :to_hash

        def write_from_database(name, value)
          @attributes[name] = self[name].with_value_from_database(value)
        end

        def write_from_user(name, value)
          raise FrozenError, "can't modify frozen attributes" if frozen?
          @attributes[name] = self[name].with_value_from_user(value)
          value
        end

        def write_cast_value(name, value)
          @attributes[name] = self[name].with_cast_value(value)
          value
        end

        def freeze
          attributes.freeze
          super
        end

        def deep_dup
          ActiveModel::AttributeSet.new(attributes.deep_dup)
        end

        def initialize_dup(_)
          @attributes = @attributes.dup
          super
        end

        def initialize_clone(_)
          @attributes = @attributes.clone
          super
        end

        def accessed
          attributes.each_key.select { |name| self[name].has_been_read? }
        end

        def slice!(*keep)
          attributes.slice!(*keep)
          self
        end

        protected
          attr_reader :attributes

        private
          def default_attribute(name)
            ActiveModel::Attribute.null(name)
          end
      end
    end
  end

  module AttributeSetBuilderOverrides # :nodoc:
    def self.prepended(base)
      base.class_eval do
        attr_reader :types, :default_attributes

        def build_from_database(values = {}, additional_types = {})
          LazyAttributeSet.new(values, types, additional_types, default_attributes)
        end
      end
      ActiveModel.const_set(:LazyAttributeSet, LazyAttributeSet)
    end

    class LazyAttributeSet < ActiveModel::AttributeSet # :nodoc:
      def initialize(values, types, additional_types, default_attributes, attributes = {})
        super(attributes)
        @values = values
        @types = types
        @additional_types = additional_types
        @default_attributes = default_attributes
        @casted_values = {}
        @materialized = false
      end

      def key?(name)
        (values.key?(name) || types.key?(name) || @attributes.key?(name)) && self[name].initialized?
      end

      def keys
        keys = values.keys | types.keys | @attributes.keys
        keys.keep_if { |name| self[name].initialized? }
      end

      def fetch_value(name, &block)
        if attr = @attributes[name]
          return attr.value(&block)
        end

        @casted_values.fetch(name) do
          value_present = true
          value = values.fetch(name) { value_present = false }

          if value_present
            type = additional_types.fetch(name, types[name])
            @casted_values[name] = type.deserialize(value)
          else
            attr = default_attribute(name, value_present, value)
            attr.value(&block)
          end
        end
      end

      def slice!(*keep)
        [ values, types, @attributes ].each { |v| v.slice!(*keep) }
        self
      end

      protected
        def attributes
          unless @materialized
            values.each_key { |key| self[key] }
            types.each_key { |key| self[key] }
            @materialized = true
          end
          @attributes
        end

      private
        attr_reader :values, :types, :additional_types, :default_attributes

        def default_attribute(
          name,
          value_present = true,
          value = values.fetch(name) { value_present = false }
        )
          type = additional_types.fetch(name, types[name])

          if value_present
            @attributes[name] = ActiveModel::Attribute.from_database(name, value, type, @casted_values[name])
          elsif types.key?(name)
            if attr = default_attributes[name]
              @attributes[name] = attr.dup
            else
              @attributes[name] = ActiveModel::Attribute.uninitialized(name, type)
            end
          else
            ActiveModel::Attribute.null(name)
          end
        end
    end
  end
end

ActiveModel::Attribute.prepend ActiveModelAttributeOverrides::AttributeOverrides

ActiveModel::AttributeSet.prepend ActiveModelAttributeOverrides::AttributeSetOverrides

ActiveModel::AttributeSet::Builder.prepend ActiveModelAttributeOverrides::AttributeSetBuilderOverrides
