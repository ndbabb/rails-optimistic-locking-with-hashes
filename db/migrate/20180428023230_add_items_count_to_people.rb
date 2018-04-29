class AddItemsCountToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :items_count, :integer, default: 0
  end
end
