class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.string :name
      t.decimal :service, precision: 1
      t.decimal :status, precision: 1
      t.float :percent_complete, default: 0.0
      t.datetime :completed_at

      t.timestamps
    end
  end
end
