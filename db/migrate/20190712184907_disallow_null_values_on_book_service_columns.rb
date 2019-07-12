class DisallowNullValuesOnBookServiceColumns < ActiveRecord::Migration[5.2]
  def change
    execute('UPDATE books SET exists_in_google = false WHERE exists_in_google IS NULL;')
    change_column_default :books, :exists_in_google, false
    change_column_null :books, :exists_in_google, false

    execute('UPDATE books SET exists_in_hathitrust = false WHERE exists_in_hathitrust IS NULL;')
    change_column_default :books, :exists_in_hathitrust, false
    change_column_null :books, :exists_in_hathitrust, false

    execute('UPDATE books SET exists_in_internet_archive = false WHERE exists_in_internet_archive IS NULL;')
    change_column_default :books, :exists_in_internet_archive, false
    change_column_null :books, :exists_in_internet_archive, false
  end
end
