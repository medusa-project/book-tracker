module TasksHelper

  def bootstrap_class_for_status(status)
    case status
      when Task::Status::SUCCEEDED
        'badge-success'
      when Task::Status::FAILED
        'badge-danger'
      when Task::Status::RUNNING
        'badge-primary'
      when Task::Status::PAUSED
        'badge-info'
    end
  end

end
