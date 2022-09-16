class StripTrailingPeriodsFromMetadata < ActiveRecord::Migration[7.0]
  def change
    # strip trailing periods in values
    execute "UPDATE books SET title = substring(title, 0, length(title)) WHERE title LIKE '%.';"
    execute "UPDATE books SET author = substring(author, 0, length(author)) WHERE author LIKE '%.';"
    execute "UPDATE books SET subject = substring(subject, 0, length(subject)) WHERE subject LIKE '%.';"
    # strip trailing periods in values separated by ||
    execute "UPDATE books SET subject = REGEXP_REPLACE(subject, '\\.\\|\\|', '||', 'g') WHERE subject LIKE '%.||%';"
  end
end
