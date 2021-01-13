class <%= migration_class_name %> < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :<%= table_name %><%= primary_key_type %> do |t|
<% attributes.each do |attribute| -%>
<% if attribute.password_digest? -%>
      t.text :password_digest<%= attribute.inject_options %>
<% elsif attribute.token? -%>
      t.text :<%= attribute.name %><%= attribute.inject_options %>
<% else -%>
      t.<%= attribute.type %> :<%= attribute.name %><%= attribute.type.in?(%i[ references boolean ]) ? ", null: false" : "" %><%= attribute.type == :boolean ? ", default: false" : "" %><%= attribute.type == :references ? ", type: :uuid" : "" %><%= attribute.inject_options %>
<% end -%>
<% end -%>
<% if options[:timestamps] %>
      t.timestamps default: -> { "NOW()" }
<% end -%>
    end
<% attributes.select(&:token?).each do |attribute| -%>
    add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>, unique: true
<% end -%>
<% attributes_with_index.each do |attribute| -%>
    add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
<% end -%>
  end
end
