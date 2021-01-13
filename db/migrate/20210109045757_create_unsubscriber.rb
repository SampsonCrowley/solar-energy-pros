class CreateUnsubscriber < ActiveRecord::Migration[6.0]
  def change
    create_table :unsubscriber, id: :uuid do |t|
      t.unsubscriber_category :category
      t.citext :value, null: false
      t.boolean :all, null: false, default: true

      t.index [ :category, :value ], unique: true

      t.timestamps default: -> { "NOW()" }
    end
  end
end
