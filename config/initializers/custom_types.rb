Rails.application.reloader.to_prepare do
  # ActiveRecord::Type.register(:indifferent_jsonb, IndifferentJsonb::Type, adapter: :postgresql, override: true)
  ActiveRecord::Type.register(:unsubscriber_category, UnsubscriberCategory::Type, adapter: :postgresql, override: true)


  ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb.prepend IndifferentJsonb
  ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.prepend NeverNilArray
  ActiveRecord::ConnectionAdapters::TableDefinition.include UnsubscriberCategory::TableDefinition

  ActiveModel::Type::Boolean.prepend StrictBoolean
end
