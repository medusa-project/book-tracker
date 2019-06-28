##
# Checks Internet Archive for bibliographic data and updates the
# corresponding local books with its findings.
#
class InternetArchive

  def self.check_in_progress?
    Task.where(service: Service::INTERNET_ARCHIVE).
        where('status NOT IN (?)', [Status::SUCCEEDED, Status::FAILED]).
        limit(1).any?
  end

  def check
    if RecordSource.import_in_progress? or Service.check_in_progress?
      raise 'Cannot check Internet Archive while another import or service '\
      'check is in progress.'
    end

    task = Task.create!(name: 'Checking Internet Archive',
                        service: Service::INTERNET_ARCHIVE)

    begin
      doc = get_api_results(task)

      items_in_ia = 0
      num_items = doc.xpath('//result/@numFound').first.content.to_i

      task.name = 'Checking Internet Archive: Scanning the inventory for '\
      'UIU records...'
      task.save!
      puts task.name

      doc.xpath('//result/doc/str').each_with_index do |node, index|
        book = Book.find_by_ia_identifier(node.content)
        if book
          book.exists_in_internet_archive = true
          book.save!
          items_in_ia += 1
        end

        if index % 500 == 0
          task.percent_complete = (index + 1).to_f / num_items.to_f
          task.save!
        end
      end
    rescue SystemExit, Interrupt => e
      task.name = "Internet Archive check failed: #{e}"
      task.status = Status::FAILED
      task.save!
      puts task.name
      raise e
    rescue => e
      task.name = "Internet Archive check failed: #{e}"
      task.status = Status::FAILED
      task.save!
      puts task.name
      raise e
    else
      task.name = "Checking Internet Archive: Updated database with "\
      "#{items_in_ia} found items."
      task.status = Status::SUCCEEDED
      task.save!
      puts task.name
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
                    command: ['bin/rails', 'books:check_internet_archive']
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
  # Gets all UIUC records from IA, downloading and caching them if necessary,
  # or returning the current date's cached copy if available.
  #
  # @return [Nokogiri::XML::Document]
  #
  def get_api_results(task)
    expected_filename = "ia_results_#{Date.today.strftime('%Y%m%d')}.xml"
    cache_pathname = Rails.root.join('tmp')
    expected_pathname = File.join(cache_pathname, expected_filename)

    unless File.exists?(expected_pathname)
      # Delete older downloads
      Dir.glob(File.join(cache_pathname, 'ia_results_*')).
          each{ |f| File.delete(f) }

      task.name = 'Checking Internet Archive: Downloading UIUC inventory'
      task.save!
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
        puts "Getting #{uri}"
        Net::HTTP.get_response(uri) do |res|
          res.read_body do |chunk|
            File.open(expected_pathname, 'ab') do |file|
              file.write(chunk)
            end
          end
        end
      rescue => e
        puts "#{e}"
        File.delete(expected_pathname) if File.exists?(expected_pathname)
        raise e
      end
    end
    File.open(expected_pathname) { |f| Nokogiri::XML(f) }
  end

end
