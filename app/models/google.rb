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
        count > 0
  end

  ##
  # @param inventory_key [String] Object key of a Google Books inventory file
  #                               in S3.
  #
  def initialize(inventory_key)
    @inventory_key = inventory_key
  end

  def check
    if RecordSource.import_in_progress? or Service.check_in_progress?
      raise 'Cannot check Google while another import or service '\
      'check is in progress.'
    end

    task = Task.create!(name: 'Checking Google', service: Service::GOOGLE)
    puts task.name

    bt_items_in_gb = new_bt_items_in_gb = num_skipped_lines = 0

    config = Configuration.instance
    opts = {
        region: config.aws_region,
        force_path_style: true,
        credentials: Aws::Credentials.new(config.aws_access_key_id,
                                          config.aws_secret_access_key)
    }
    opts[:endpoint] = config.s3_endpoint if config.s3_endpoint.present?
    client = Aws::S3::Client.new(opts)

    begin
      response = client.get_object(bucket: config.temp_bucket,
                                   key: @inventory_key)
      # CSV columns:
      # [0] barcode
      # [1] scanned date
      # [2] processed date
      # [3] analyzed date
      # [4] converted date
      # [5] downloaded date
      # Date format: yyyy-mm-dd hh:mm
      response.body.each_line.with_index do |line, index|
        begin
          parts = CSV.parse_line(line, col_sep: "\t")
          if parts.any?
            book = Book.find_by_obj_id(parts.first.strip)
            if book
              unless book.exists_in_google
                book.update!(exists_in_google: true)
                new_bt_items_in_gb += 1
              end
              bt_items_in_gb += 1
            end
          end
        rescue
          num_skipped_lines += 1
        end
        if index % 1000 == 0
          task.update(name: "Checking Google: scanned #{index} records "\
                      "(no progress available)")
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
      client.delete_object(bucket: config.temp_bucket,
                           key: @inventory_key)
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
                    command: ['bin/rails', "books:check_google[#{@inventory_key}]"]
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
