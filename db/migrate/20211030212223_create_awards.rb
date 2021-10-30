class CreateAwards < ActiveRecord::Migration[6.1]
  def change
    create_table :awards do |t|
      t.references :filer, null: false, foreign_key: true
      t.string :purpose
      t.decimal :cash_amount

      t.timestamps
    end
  end
end
