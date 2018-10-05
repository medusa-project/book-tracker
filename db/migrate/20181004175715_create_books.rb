class CreateBooks < ActiveRecord::Migration[5.2]
  def change
    create_table :books do |t|
      t.integer :bib_id
      t.string :oclc_number
      t.string :obj_id
      t.string :title
      t.string :author
      t.string :volume
      t.string :date
      t.string :language
      t.string :subject
      t.boolean :exists_in_hathitrust, default: false
      t.boolean :exists_in_internet_archive, default: false
      t.boolean :exists_in_google, default: false
      t.string :ia_identifier
      t.string :hathitrust_rights
      t.string :hathitrust_access
      t.string :source_path
      t.text :raw_marcxml

      t.timestamps
    end

    add_index :books, :author
    add_index :books, :bib_id
    add_index :books, :date
    add_index :books, :exists_in_google
    add_index :books, :exists_in_hathitrust
    add_index :books, :exists_in_internet_archive
    add_index :books, :hathitrust_access
    add_index :books, :ia_identifier
    add_index :books, :obj_id
    add_index :books, :oclc_number
    add_index :books, :title
    add_index :books, :volume
  end
end
