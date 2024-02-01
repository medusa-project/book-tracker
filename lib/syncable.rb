module Syncable
  ##
  # Invokes a rake task via an ECS task to check the service.
  #
  # @param task [Task]
  # @return [void]
  #
  def run_task(model, task)

    unless Rails.env.production? or Rails.env.demo? 
      raise 'This feature only works in production. '\
          'Elsewhere, use a rake task instead.'
    end

    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/ECS/Client.html#run_task-instance_method
    config = Configuration.instance
    ecs = Aws::ECS::Client.new
    command = generate_command(model, task)

    args = {
        cluster: config.ecs_cluster,
        task_definition: config.ecs_async_task_definition,
        launch_type: 'FARGATE',
        overrides: {
            container_overrides: [
                {
                    name: config.ecs_async_task_container,
                    command: command 
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

  def generate_command(model, task)
    case model 
      when :internet_archive 
        ['bin/rails', "books:check_internet_archive[#{task.id}]"]
      when :hathitrust 
        ['bin/rails', "books:check_hathitrust[#{task.id}]"]
      when :google
        ['bin/rails', "books:check_google[#{@inventory_key},#{task.id}]"]
      when :record_source  
        ['bin/rails', "books:import[#{task.id}]"]
      else
        "no such model"
    end
  end
end