class AddCompoundIndexOnBookServiceColumns < ActiveRecord::Migration[5.2]
  def change
    add_index :books, [:exists_in_hathitrust, :exists_in_internet_archive, :exists_in_google],
              name: 'index_books_on_service_existence_columns'
  end
end
