##
# Checks Google for bibliographic data using Google GRIN, and updates the
# corresponding local books with its findings.
#
# Access to GRIN is limited by IP address. If a request to
# https://books.google.com/libraries/UIUC/ returns HTTP 403, contact Jon
# Gorman (jtgorman@illinois.edu) in Library IT to request access.
#
class Google

  def self.check_in_progress?
    Task.where(service: Service::GOOGLE).
        where('status NOT IN (?)', [Status::SUCCEEDED, Status::FAILED]).
        limit(1).any?
  end

  ##
  # @param inventory_pathname [String] Pathname of a Google Books inventory
  #                                    file.
  #
  def initialize(inventory_pathname)
    @inventory_pathname = inventory_pathname
  end

  def check
    if RecordSource.import_in_progress? or Service.check_in_progress?
      raise 'Cannot check Google while another import or service '\
      'check is in progress.'
    end

    task = Task.create!(name: 'Checking Google', service: Service::GOOGLE)
    puts task.name

    begin
      bt_items_in_gb = 0
      new_bt_items_in_gb = 0
      num_lines = 0
      num_skipped_lines = 0

      # Count the lines in order to display progress.
      File.readlines(@inventory_pathname).each do
        num_lines += 1;
      end

      # File columns: [0] barcode, [1] scanned date, [2] processed date,
      # [3] analyzed date, [4] converted date, [5] downloaded date
      # Date format: yyyy-mm-dd hh:mm
      File.readlines(@inventory_pathname).each_with_index do |line, index|
        begin
          parts = CSV.parse_line(line, { col_sep: "\t" })
          if parts.any?
            book = Book.find_by_obj_id(parts.first.strip)
            if book
              unless book.exists_in_google
                book.exists_in_google = true
                book.save!
                new_bt_items_in_gb += 1
              end
              bt_items_in_gb += 1
            end
          end
        rescue
          num_skipped_lines += 1
        end
        if index % 1000 == 0
          task.percent_complete = (index + 1).to_f / num_lines.to_f
          task.save!
        end
      end
    rescue SystemExit, Interrupt => e
      task.name = "Google check failed: #{e}"
      task.status = Status::FAILED
      task.save!
      puts task.name
      raise e
    rescue => e
      task.name = "Google check failed: #{e}"
      task.status = Status::FAILED
      task.save!
      puts task.name
    else
      task.name = "Checking Google: Updated database with #{new_bt_items_in_gb} "\
      "new items out of #{bt_items_in_gb} total book tracker items in "\
      "Google; #{num_skipped_lines} lines malformed/skipped."
      task.status = Status::SUCCEEDED
      task.save!
      puts task.name
    ensure
      File.delete(@inventory_pathname) rescue nil
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
                    command: ['bin/rails', 'books:check_google']
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

end
