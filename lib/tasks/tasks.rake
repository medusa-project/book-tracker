namespace :tasks do

  desc 'Stop all running tasks'
  task stop_running: :environment do
    # N.B.: this doesn't stop any running ECS tasks.
    Task.where(status: Task::Status::RUNNING).each do |task|
      task.update!(status: Task::Status::FAILED)
    end
  end

end
