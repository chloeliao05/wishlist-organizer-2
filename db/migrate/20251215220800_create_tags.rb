class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.integer :user_id
      t.string :name
      t.string :tag_type

      t.timestamps
    end
  end
end
