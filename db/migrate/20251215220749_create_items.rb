class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.integer :user_id
      t.string :title
      t.string :url
      t.string :price
      t.string :currency
      t.string :image_url
      t.text :notes
      t.string :priority
      t.string :status
      t.date :buy_by
      t.text :description
      t.string :brand

      t.timestamps
    end
  end
end
