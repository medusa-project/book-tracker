##
# Checks HathiTrust for bibliographic data and updates the corresponding
# local books with its findings.
#
class Hathitrust
  include Syncable 

  ##
  # @return [Boolean] Whether an invocation of check() is authorized.
  #
  def self.check_authorized?
    Task.where(service: Service::HATHITRUST).
        where('status IN (?)', [Task::Status::RUNNING]).count == 0
  end

  ##
  # Checks HathiTrust by downloading the latest HathiFile
  # (http://www.hathitrust.org/hathifiles).
  #
  # @param task [Task] Optional. If not provided, one will be created.
  #
  def check(task = nil)
    raise 'Another HathiTrust check is in progress.' unless self.class.check_authorized?

    task_args = {
        name: 'Checking HathiTrust',
        service: Service::HATHITRUST,
        status: Task::Status::RUNNING
    }
    if task
      Rails.logger.info('Hathitrust.check(): updating provided Task')
      task.update!(task_args)
    else
      Rails.logger.info('Hathitrust.check(): creating new Task')
      task = Task.create!(task_args)
    end

    config = Configuration.instance
    pathname = nil
    begin
      uri      = find_hathifile_url(task)
      pathname = download_hathifile(uri, task)
      nuc_code = config.library_nuc_code

      task.update!(name: 'Checking HathiTrust: compiling a row count...')
      puts task.name

      num_lines = File.foreach(pathname).count

      task.update!(name: 'Checking HathiTrust: scanning the HathiFile...')

      # http://www.hathitrust.org/hathifiles_description
      File.open(pathname).each_with_index do |line, index|
        parts = line.split("\t")
        if parts[5] == nuc_code
          book = Book.find_by_obj_id(parts[0].split('.').last)
          next unless book
          if !book.exists_in_hathitrust ||
              book.hathitrust_access != parts[1] ||
              book.hathitrust_rights != parts[2]
            book.update!(exists_in_hathitrust: true,
                         hathitrust_access:    parts[1],
                         hathitrust_rights:    parts[2])
          end
        end

        if index % 1000 == 0
          task.update!(percent_complete: (index + 1).to_f / num_lines.to_f)
          print "\r#{task.name} (#{(task.percent_complete * 100).round(2)}%)"
        end
      end
    rescue SystemExit, Interrupt => e
      task.update!(name: "HathiTrust check failed: #{e}",
                   status: Task::Status::FAILED)
      puts task.name
      raise e
    rescue => e
      Rails.logger.error("Hathitrust.check(): #{e}")
      task.update!(name: "HathiTrust check failed: #{e}",
                   status: Task::Status::FAILED)
      raise e
    else
      task.name = "Checking HathiTrust: updated database with "\
        "#{Book.where(exists_in_hathitrust: true).count} found items."
      task.status = Task::Status::SUCCEEDED
      task.save!
      puts task.name
    ensure
      FileUtils.rm(pathname, force: true) if pathname.present?
      Book.analyze_table
    end
  end

  ##
  # Invokes a rake task via an ECS task to check the service.
  #
  # @param task [Task]
  # @return [void]
  #
  def check_async
    run_task(:hathitrust, task)
  end

  private
  
  def find_hathifile_url(task)
    # As there is no single URI for the latest HathiFile, we have to scrape
    # the HathiFile listing out of the index HTML page.
    task.update!(name: 'Checking HathiTrust: downloading HathiFile index...')
    puts task.name

    uri          = URI.parse('https://www.hathitrust.org/hathifiles')
    response     = Net::HTTP.get_response(uri)
    location     = response['location']
    base_url     = 'https://www.hathitrust.org'
    res          = base_url + location

    if response.code.start_with?("3")
      new_response = Net::HTTP.get_response(URI(res))
      page         = Nokogiri::HTML(new_response.body)
    else
      page         = Nokogiri::HTML(response.body)
    end

    # Scrape the URI of the latest HathiFile out of the index
    node     = page.css('.btable-wrapper table.btable tbody tr td a')
                   .select{ |h| h.text.start_with?('hathi_full_') }
                   .sort{ |x,y| x.text <=> y.text }
                   .reverse[0]
    node['href']
  end

  ##
  # @param uri [String] The URI/URL at which the HathiFile resides.
  # @param task [Task]
  # @return [String] Pathname of the downloaded HathiFile.
  #
  def download_hathifile(uri, task)
    filename = File.basename(uri)
    Tempfile.open(%w[hathifile, .gz]) do |gz_tempfile|
      task.update!(name: "Checking HathiTrust: downloading the latest HathiFile "\
        "(#{filename})...")
      puts task.name

      # Progressively download it (it's big).
      Net::HTTP.get_response(URI.parse(uri)) do |response|
        response.read_body do |chunk|
          File.open(gz_tempfile.path, 'ab') do |file|
            file.write(chunk)
          end
        end
      end

      # Decompress it.
      task.update!(name: 'Checking HathiTrust: unzipping the HathiFile...')
      puts task.name

      `gunzip "#{gz_tempfile.path}"`

      return gz_tempfile.path.chomp(".gz")
    end
  end

end
