module TasksHelper

  def bootstrap_class_for_status(status)
    case status
      when Task::Status::SUCCEEDED
        'text-success'
      when Task::Status::FAILED
        'text-danger'
      when Task::Status::RUNNING
        'text-primary'
      when Task::Status::PAUSED
        'text-info'
    end
  end

end
