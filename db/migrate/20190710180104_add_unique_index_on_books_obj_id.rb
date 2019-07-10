class AddUniqueIndexOnBooksObjId < ActiveRecord::Migration[5.2]
  def change
    remove_index :books, :obj_id
    add_index :books, :obj_id, unique: true
  end
end
