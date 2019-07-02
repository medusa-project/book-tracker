##
# N.B.: these tasks are invoked by the ECS API, not just on the console, so
# changing their names requires updating those invocations.
#
namespace :books do
  desc 'Scans for MARCXML records to import, and imports them.'
  task import: :environment do
    RecordSource.new.import
  end

  desc 'Checks to see whether each book exists in Google.'
  task :check_google, [:key] => :environment do |task, args|
    Google.new(args[:key]).check
  end

  desc 'Checks to see whether each book exists in HathiTrust.'
  task check_hathitrust: :environment do
    Hathitrust.new.check
  end

  desc 'Checks to see whether each book exists in Internet Archive.'
  task check_internet_archive: :environment do
    InternetArchive.new.check
  end

end
