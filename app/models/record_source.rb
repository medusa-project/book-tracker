##
# Source of MARCXML records--currently an S3 bucket.
#
class RecordSource

  MARCXML_NAMESPACES = { 'marc' => 'http://www.loc.gov/MARC21/slim' }

  def self.import_in_progress?
    Task.where(service: Service::LOCAL_STORAGE).
        where('status NOT IN (?)', [Status::SUCCEEDED, Status::FAILED]).count > 0
  end

  ##
  # Imports records from a tree of MARCXML files, updating them if one with
  # the same bib ID already exists, and adding them if not.
  #
  # See: https://docs.aws.amazon.com/sdk-for-ruby/index.html#lang/en_us
  # See: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html
  #
  def import
    if Service.check_in_progress?
      raise 'Cannot import while another import or service check is in progress.'
    end

    task = Task.create!(name: 'Importing MARCXML records',
                        service: Service::LOCAL_STORAGE)

    begin
      config = Configuration.instance
      opts = {
          region: config.aws_region,
          force_path_style: true,
          credentials: Aws::Credentials.new(config.aws_access_key_id,
                                            config.aws_secret_access_key)
      }
      opts[:endpoint] = config.s3_endpoint if config.s3_endpoint.present?

      client = Aws::S3::Client.new(opts)

      num_inserted = num_updated = num_invalid_files = file_index =
          record_index = 0
      client.list_objects(
          bucket: config.s3_bucket,
          prefix: config.s3_key_prefix).each do |list_response|
        list_response.contents.each do |object|
          next unless object.key.downcase.end_with?('.xml')

          get_response = client.get_object(
              bucket: config.s3_bucket,
              key: object.key)
          data = get_response.body.read

          begin
            doc = Nokogiri::XML(data, &:noblanks)
            doc.encoding = 'utf-8'

            doc.xpath('//marc:record', MARCXML_NAMESPACES).each do |record|
              book, status = Book.insert_or_update!(
                  Book.params_from_marcxml_record(record),
                  object.key)
              if status == Book::INSERTED
                num_inserted += 1
              else
                num_updated += 1
              end
              record_index += 1
              if record_index % 1000 == 0
                task.update(name: "Importing MARCXML records: "\
                    "scanned #{record_index} records in #{file_index + 1} files "\
                    "(no progress available)")
                print "#{task.name.ljust(80)}\r"
              end
            end
          rescue => e
            # This is probably an undefined namespace prefix error, which means
            # it's either an invalid MARCXML file or, more likely, a non-
            # MARCXML XML file, which is fine.
            num_invalid_files += 1
            Rails.logger.info("#{object}: #{e}")
          ensure
            file_index += 1
          end
        end
      end
    rescue SystemExit, Interrupt => e
      task.update(name: "Import failed: #{e}",
                  status: Status::FAILED)
      puts task.name
      raise e
    rescue => e
      task.update(name: "Import failed: #{e}",
                  status: Status::FAILED)
      puts task.name
      puts e.backtrace
    else
      task.update(name: sprintf('Importing MARCXML records: %d records added; %d '\
                                'records updated or unchanged; %d skipped files',
                                num_inserted, num_updated, num_invalid_files),
                  status: Status::SUCCEEDED)
      puts task.name
    end
  end

  ##
  # Invokes a rake task via an ECS task to import records.
  #
  # @return [void]
  #
  def import_async
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
                    command: ['bin/rails', 'books:import']
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
