class ChangeBibIdToStringInBooks < ActiveRecord::Migration[7.1]
  def change
    change_column :books, :bib_id, :string
  end
end
