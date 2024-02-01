##
# Checks Internet Archive for bibliographic data and updates the
# corresponding local books with its findings.
#
class InternetArchive
  include Syncable 

  TASK_UPDATE_INTERVAL = 1000
  UPDATE_BATCH_SIZE    = 1000

  ##
  # @return [Boolean] Whether an invocation of check() is authorized.
  #
  def self.check_authorized?
    Task.where(service: Service::INTERNET_ARCHIVE).
        where('status IN (?)', [Task::Status::RUNNING]).count == 0
  end

  ##
  # @param task [Task] Optional. If not provided, one will be created.
  #
  def check(task = nil)
    raise 'Another Internet Archive check is in progress.' unless self.class.check_authorized?

    task_args = {
        name: 'Checking Internet Archive: querying the API...',
        service: Service::INTERNET_ARCHIVE,
        status: Task::Status::RUNNING
    }
    if task
      Rails.logger.info('InternetArchive.check(): updating provided Task')
      task.update!(task_args)
    else
      Rails.logger.info('InternetArchive.check(): creating new Task')
      task = Task.create!(task_args)
    end

    reported_num_items = actual_num_items = 0
    ia_id_batch = []

    begin
      doc = get_api_results(task)

      reported_num_items = doc.xpath('//result/@numFound').first.content.to_i

      task.update!(name: 'Checking Internet Archive: scanning the inventory '\
          'for UIU records...')
      puts task.name

      doc.xpath('//result/doc/str').each_with_index do |node, index|
        actual_num_items += 1
        ia_id_batch << node.content
        set_existing_if_necessary(ia_id_batch)

        if index % TASK_UPDATE_INTERVAL == 0
          task.update!(name: "Checking Internet Archive: scanned "\
                             "#{actual_num_items} records...",
                       percent_complete: (index + 1) / reported_num_items.to_f)
        end
      end
    rescue SystemExit, Interrupt => e
      task.update!(name: "Internet Archive check failed: #{e}",
                   status: Task::Status::FAILED)
      puts task.name
      raise e
    rescue => e
      Rails.logger.error("InternetArchive.check(): #{e}")
      task.update!(name: "Internet Archive check failed: #{e}",
                   status: Task::Status::FAILED)
      raise e
    else
      task.update!(name: "Checking Internet Archive: updated database with "\
                         "#{actual_num_items} found items.",
                   status: Task::Status::SUCCEEDED)
      puts task.name
    ensure
      set_existing(ia_id_batch)
    end
  end

  ##
  # Invokes a rake task via an ECS task to check the service.
  #
  # @param task [Task]
  # @return [void]
  #
  def check_async
    run_task(:internet_archive, task)
  end

  private

  ##
  # Gets all UIUC records from IA, downloading and caching them if necessary,
  # or returning the current date's cached copy if available.
  #
  # @return [Nokogiri::XML::Document]
  #
  def get_api_results(task)
    expected_filename = "ia_results_#{Date.today.strftime('%Y%m%d')}.xml"
    cache_pathname    = Rails.root.join('tmp')
    expected_pathname = File.join(cache_pathname, expected_filename)

    unless File.exist?(expected_pathname)
      # Delete older downloads.
      # (This code is from when the application ran in a persistent VM; now
      # that it runs in ephemeral containers, it's not needed anymore, but it
      # doesn't hurt.)
      Dir.glob(File.join(cache_pathname, 'ia_results_*')).
          each{ |f| File.delete(f) }

      task.update!(name: 'Checking Internet Archive: downloading the UIUC inventory')
      puts task.name

      # https://archive.org/advancedsearch.php
      start_date = '1980-01-01'
      end_date = Date.today.strftime('%Y-%m-%d')
      uri = URI.parse("https://archive.org/advancedsearch.php?q="\
      "mediatype:texts AND contributor:\"University of Illinois Urbana-"\
      "Champaign\" AND updatedate:[#{start_date} TO #{end_date}]&"\
      "fl[]=identifier&rows=9999999&page=1&output=xml&save=yes")

      FileUtils.mkdir_p(cache_pathname)
      begin
        Rails.logger.info("InternetArchive.get_api_results(): GET #{uri}")
        Net::HTTP.get_response(uri) do |res|
          res.read_body do |chunk|
            File.open(expected_pathname, 'ab') do |file|
              file.write(chunk)
            end
          end
        end
      rescue => e
        Rails.logger.error("InternetArchive.get_api_results(): #{e}")
        File.delete(expected_pathname) if File.exist?(expected_pathname)
        raise e
      end
    end
    File.open(expected_pathname) { |f| Nokogiri::XML(f) }
  end

  ##
  # @param batch [Array<String>] Batch of IA identifiers.
  # @return [void]
  #
  def set_existing(batch)
    Book.bulk_update(batch, 'exists_in_internet_archive', 'true', 'ia_identifier')
    Book.analyze_table
  ensure
    batch.clear
  end

  def set_existing_if_necessary(batch)
    set_existing(batch) if batch.length >= UPDATE_BATCH_SIZE
  end

end
