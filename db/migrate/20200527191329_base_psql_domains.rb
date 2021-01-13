class BasePsqlDomains < ActiveRecord::Migration[6.0]
  def up
    type_names.each do |type|
      execute File.read(Rails.root.join("db", "sql", "domains", "#{type}.psql"))
    end
  end

  def down
    type_names.reverse.each do |type|
      execute "DROP DOMAIN IF EXISTS #{type};"
    end
  end

  private
    def type_names
      %w[
        exchange_rate_integer
        institution_category
        money_integer
        three_state
        unsubscriber_category
      ]
    end
end
