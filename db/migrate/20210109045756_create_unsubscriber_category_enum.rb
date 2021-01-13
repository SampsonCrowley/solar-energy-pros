class CreateUnsubscriberCategoryEnum < ActiveRecord::Migration[6.0]
  def up
    execute File.read(Rails.root.join("db", "sql", "domains", "unsubscriber_category.psql"))
  end
end
