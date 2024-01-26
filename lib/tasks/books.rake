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

  desc 'Iterates through books to make request to open library api and download/store image to s3 bucket.'
  task :download_book_covers, [:task_id] => :environment do 
    require 'net/http'

    # loads prior Rails tasks and entire application code needed for new rake task to interact // 
    # this ensures pry session is hit
    Rails.application.load_tasks 
    Rails.application.eager_load!

    
    s3 = Aws::S3::Client.new(
      access_key_id: Configuration.instance.storage[:books][:access_key_id],
      secret_access_key: Configuration.instance.storage[:books][:secret_access_key],
      region: Configuration.instance.storage[:books][:region]
    )
    Book.all.each do |book|
      uri = URI("http://covers.openlibrary.org/b/oclc/#{book.oclc_number}-L.jpg")
      response = Net::HTTP.get_response(uri)
      
      s3.put_object(
        bucket: Configuration.instance.storage[:books][:bucket],
        key: "book_covers/#{book.oclc_number}.jpg",
        body: response.body 
      )
      require 'pry'; binding.pry 
    end
  end

end
