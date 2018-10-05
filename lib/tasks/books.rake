namespace :books do
  desc 'Scans the filesystem for MARCXML records to import, and imports them.'
  task import: :environment do
    Filesystem.new.import
  end

  desc 'Checks to see whether each book exists in Google.'
  task check_google: :environment do
    Google.new.check
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
