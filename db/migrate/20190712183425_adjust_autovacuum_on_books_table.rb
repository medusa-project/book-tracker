class AdjustAutovacuumOnBooksTable < ActiveRecord::Migration[5.2]
  def change
    execute('ALTER TABLE books SET (autovacuum_vacuum_scale_factor = 0.0);')
    execute('ALTER TABLE books SET (autovacuum_vacuum_threshold = 5000);')
    execute('ALTER TABLE books SET (autovacuum_analyze_scale_factor = 0.0);')
    execute('ALTER TABLE books SET (autovacuum_analyze_threshold = 5000);')
  end
end
