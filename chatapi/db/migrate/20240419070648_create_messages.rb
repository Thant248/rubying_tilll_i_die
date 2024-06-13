class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.text :content
      t.references :user, null: true, foreign_key: true
      t.references :room, null: true, foreign_key: true

      t.timestamps
    end
  end
end
