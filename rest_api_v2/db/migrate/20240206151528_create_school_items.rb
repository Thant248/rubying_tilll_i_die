class CreateSchoolItems < ActiveRecord::Migration[7.1]
  def change
    create_table :school_items do |t|

      t.string :name
      t.string :age 
      t.string :school 
      t.string :sex
    end
  end
end
