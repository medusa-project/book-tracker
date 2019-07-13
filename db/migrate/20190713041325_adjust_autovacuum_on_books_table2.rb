class AdjustAutovacuumOnBooksTable2 < ActiveRecord::Migration[5.2]
  def change
    execute('ALTER TABLE books SET (autovacuum_vacuum_scale_factor = 0.2);')
    execute('ALTER TABLE books SET (autovacuum_vacuum_threshold = 50);')
    execute('ALTER TABLE books SET (autovacuum_analyze_scale_factor = 0.1);')
    execute('ALTER TABLE books SET (autovacuum_analyze_threshold = 50);')
  end
end
