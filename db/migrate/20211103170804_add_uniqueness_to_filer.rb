class AddUniquenessToFiler < ActiveRecord::Migration[6.1]
  def change
    add_index :filers, :ein, unique: true
  end
end
