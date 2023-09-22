##
# Checks HathiTrust for bibliographic data and updates the corresponding
# local books with its findings.
#
class Hathitrust

  TEMP_DIR = Rails.root.join('tmp')

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
      pathname = get_hathifile(task)
      nuc_code = config.library_nuc_code

      task.update!(name: 'Checking HathiTrust: scanning the HathiFile...')
      puts task.name

      num_lines = File.foreach(pathname).count

      # http://www.hathitrust.org/hathifiles_description
      File.open(pathname).each_with_index do |line, index|
        parts = line.split("\t")
        if parts[5] == nuc_code
          book = Book.find_by_obj_id(parts[0].split('.').last)
          if book
            if !book.exists_in_hathitrust or
                book.hathitrust_access != parts[1] or
                book.hathitrust_rights != parts[2]
              book.exists_in_hathitrust = true
              book.hathitrust_access = parts[1]
              book.hathitrust_rights = parts[2]
              book.save!
            end
          end
        end

        if index % 20000 == 0
          task.percent_complete = (index + 1).to_f / num_lines.to_f
          task.save!
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
  def check_async(task)
    unless Rails.env.production? or Rails.env.demo?
      raise 'This feature only works in production. '\
          'Elsewhere, use a rake task instead.'
    end

    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/ECS/Client.html#run_task-instance_method
    config = Configuration.instance
    ecs = Aws::ECS::Client.new
    args = {
        cluster: config.ecs_cluster,
        task_definition: config.ecs_async_task_definition,
        launch_type: 'FARGATE',
        overrides: {
            container_overrides: [
                {
                    name: config.ecs_async_task_container,
                    command: ['bin/rails', "books:check_hathitrust[#{task.id}]"]
                },
            ]
        },
        network_configuration: {
            awsvpc_configuration: {
                subnets: [config.ecs_subnet],
                security_groups: [config.ecs_security_group],
                assign_public_ip: 'ENABLED'
            },
        }
    }
    ecs.run_task(args)
  end

  private
  
  ##
  # Downloads the latest HathiFile.
  #
  # @return The path of the HathiFile
  #
      

  def get_hathifile(task)
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

    node = page.css('.btable-wrapper table.btable tbody tr td a')
                    .select{ |h| h.text.start_with?('hathi_full_') }
                    .sort{ |x,y| x.text <=> y.text }.reverse[0]
    
    uri          = node['href']
    gz_filename  = node.text
    txt_filename = gz_filename.chomp('.gz')
    gz_pathname  = File.join(TEMP_DIR, gz_filename)
    txt_pathname = File.join(TEMP_DIR, txt_filename)  

    # If we already have it, return its pathname instead of downloading it.
    return txt_pathname if File.exists?(txt_pathname)

    # Otherwise, delete any older HathiFiles that may exist, as they are now
    # out-of-date.
    # (This code is from when the application ran in a persistent VM; now
    # that it runs in ephemeral containers, it's not needed anymore, but it
    # doesn't hurt.)

    Dir.glob(File.join(TEMP_DIR, 'hathi_full_*.txt')).
        each { |f| File.delete(f) }

    # And progressively download the new one (because it's big)
    task.name = "Checking HathiTrust: downloading the latest HathiFile "\
    "(#{gz_filename})..."
    task.save!
    puts task.name

    FileUtils::mkdir_p(TEMP_DIR)
    Net::HTTP.get_response(URI.parse(uri)) do |res|
      res.read_body do |chunk|
        File.open(gz_pathname, 'ab') { |file|
          file.write(chunk)
      }
    end
  end

    task.name = 'Checking HathiTrust: unzipping the HathiFile...'
    task.save!
    puts task.name
    `gunzip #{gz_pathname}`

    txt_pathname
  end
end
