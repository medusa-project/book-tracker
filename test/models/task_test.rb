require 'test_helper'

class TaskTest < ActiveSupport::TestCase
  test "Status::to_s returns 'Submitted' for SUBMITTED status" do 
    assert_equal 'Submitted', Task::Status.to_s(Task::Status::SUBMITTED)
  end    

  test "Status::to_s returns 'Running' for RUNNING status" do 
    assert_equal 'Running', Task::Status.to_s(Task::Status::RUNNING)
  end

  test "Status::to_s returns 'Paused' for PAUSED status" do 
    assert_equal 'Paused', Task::Status.to_s(Task::Status::PAUSED)
  end

  test "Status::to_s returns 'Succeeded' for SUCCEEDED status" do
    assert_equal 'Succeeded', Task::Status.to_s(Task::Status::SUCCEEDED)
  end

  test "Status::to_s returns 'Failed' for FAILED status" do 
    assert_equal 'Failed', Task::Status.to_s(Task::Status::FAILED)
  end

  test "Task.new creates new task object defaulting to status of 'RUNNING' (1) and service of nil" do 
    task = Task.new 

    assert_equal 1, task.status
    assert_nil task.service 
  end

  test "Status can be equal to SUCCEEDED (3)" do 
    task = Task.new 
    task.status=(3)

    assert_equal 3, task.status 
  end

  test "Service can be set to equal LOCAL_STORAGE" do 
    task = Task.new 
    task.service=(Service::LOCAL_STORAGE)

    assert_equal 3, task.service 
  end

  test ".import_task_completed? will return true under correct conditions" do 
    task = Task.new 
    task.status=(4)
    task.service=(Service::LOCAL_STORAGE) 

    assert_equal true, task.import_task_completed?
  end

  test ".trigger_hathitrust_check will start the hathitrust check process" do 
    task = Task.new
    task.status=(4)
    task.service=(Service::LOCAL_STORAGE)
    task.import_task_completed?

    assert_not_nil task.trigger_hathitrust_check
  end

end





