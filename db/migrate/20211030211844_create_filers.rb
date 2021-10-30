class CreateFilers < ActiveRecord::Migration[6.1]
  def change
    create_table :filers do |t|
      t.integer :ein
      t.string :name
      t.string :address
      t.string :city
      t.string :state
      t.integer :zip

      t.timestamps
    end
  end
end
