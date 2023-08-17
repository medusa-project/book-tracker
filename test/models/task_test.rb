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
end


