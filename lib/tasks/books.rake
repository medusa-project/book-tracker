##
# N.B.: these tasks are invoked by the ECS API, not just on the console, so
# changing their names requires updating those invocations.
#
namespace :books do
  desc 'Scans for MARCXML records to import, and imports them.'
  task :import, [:task_id] => :environment do |task, args|
    t = args[:task_id].present? ? Task.find(args[:task_id]) : nil
    RecordSource.new.import(t)
  end

  desc 'Checks to see whether each book exists in Google.'
  task :check_google, [:key, :task_id] => :environment do |task, args|
    t = args[:task_id].present? ? Task.find(args[:task_id]) : nil
    Google.new(args[:key]).check(t)
  end

  desc 'Checks to see whether each book exists in HathiTrust.'
  task :check_hathitrust, [:task_id] => :environment do |task, args|
    t = args[:task_id].present? ? Task.find(args[:task_id]) : nil
    Hathitrust.new.check(t)
  end

  desc 'Checks to see whether each book exists in Internet Archive.'
  task :check_internet_archive, [:task_id] => :environment do |task, args|
    t = args[:task_id].present? ? Task.find(args[:task_id]) : nil
    InternetArchive.new.check(t)
  end

end
