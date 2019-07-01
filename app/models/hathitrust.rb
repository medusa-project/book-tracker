##
# Checks HathiTrust for bibliographic data and updates the corresponding
# local books with its findings.
#
class Hathitrust

  TEMP_DIR = Rails.root.join('tmp')

  def self.check_in_progress?
    Task.where(service: Service::HATHITRUST).
        where('status NOT IN (?)', [Status::SUCCEEDED, Status::FAILED]).
        limit(1).any?
  end

  ##
  # Checks HathiTrust by downloading the latest HathiFile
  # (http://www.hathitrust.org/hathifiles).
  #
  def check
    if RecordSource.import_in_progress? or Service.check_in_progress?
      raise 'Cannot check HathiTrust while another import or service check is '\
      'in progress.'
    end
    task = Task.create!(name: 'Checking HathiTrust',
                        service: Service::HATHITRUST)
    puts task.name

    pathname = nil
    begin
      pathname = get_hathifile(task)
      nuc_code = Configuration.instance.library_nuc_code

      task.name = "Checking HathiTrust: Scanning the HathiFile for "\
      "#{nuc_code} records..."
      task.save!
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
      task.name = "HathiTrust check failed: #{e}"
      task.status = Status::FAILED
      task.save!
      puts task.name
      raise e
    rescue => e
      task.name = "HathiTrust check failed: #{e}"
      task.status = Status::FAILED
      task.save!
      puts task.name
    else
      task.name = "Checking HathiTrust: Updated database with "\
        "#{Book.where(exists_in_hathitrust: true).count} found items."
      task.status = Status::SUCCEEDED
      task.save!
      puts task.name
    ensure
      FileUtils.rm(pathname, force: true) if pathname.present?
    end
  end

  ##
  # Invokes a rake task via an ECS task to check the service.
  #
  # @return [void]
  #
  def check_async
    unless Rails.env.production? or Rails.env.demo?
      raise 'This feature only works in production. '\
          'Elsewhere, use a rake task instead.'
    end

    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/ECS/Client.html#run_task-instance_method
    config = Configuration.instance
    ecs = Aws::ECS::Client.new(region: config.aws_region)
    args = {
        cluster: config.ecs_cluster,
        task_definition: config.ecs_async_task_definition,
        launch_type: 'FARGATE',
        overrides: {
            container_overrides: [
                {
                    name: config.ecs_async_task_container,
                    command: ['bin/rails', 'books:check_hathitrust']
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
    task.name = 'Getting HathiFile index...'
    task.save!
    puts task.name

    uri = URI.parse('https://www.hathitrust.org/hathifiles')
    response = Net::HTTP.get_response(uri)
    page = Nokogiri::HTML(response.body)

    # Scrape the URI of the latest HathiFile out of the index
    node = page.css('div#content-area table.sticky-enabled a').
        select{ |h| h.text.start_with?('hathi_full_') }.
        sort{ |x,y| x.text <=> y.text }.reverse[0]
    uri = node['href']
    gz_filename = node.text
    txt_filename = gz_filename.chomp('.gz')
    gz_pathname = File.join(TEMP_DIR, gz_filename)
    txt_pathname = File.join(TEMP_DIR, txt_filename)

    # If we already have it, return its pathname instead of downloading it.
    return txt_pathname if File.exists?(txt_pathname)

    # Otherwise, delete any older HathiFiles that may exist, as they are now
    # out-of-date
    Dir.glob(File.join(TEMP_DIR, 'hathi_full_*.txt')).
        each { |f| File.delete(f) }

    # And progressively download the new one (because it's big)
    task.name = "Checking HathiTrust: Downloading the latest HathiFile "\
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

    task.name = 'Checking HathiTrust: Unzipping the HathiFile...'
    task.save!
    puts task.name
    `gunzip #{gz_pathname}`

    txt_pathname
  end

end