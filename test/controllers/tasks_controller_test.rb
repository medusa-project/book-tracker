require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = tasks(:one)
  end

  test "should get tasks" do
    get tasks_path
    
    assert_response :success
  end

  test "should prepare to import marcxml records" do
    post import_path(@task)

    assert_response :success
    assert_equal 200, response.status
  end

  test "should conduct a Hathitrust check" do
    
    post check_hathitrust_path

    assert_equal 200, response.status
  end

  # test "should redirect back after conducting Hathitrust check" do 
    
  #   post '/check-hathitrust'

  #   assert_redirected_to "/"
  # end

  # assert_redirected_to tasks_path 
  # follow_redirect!
  # assert_response :redirect 
  
  # get page_url, headers: { 'HTTP_REFERER': previous_page_url }
  # end

  # test "should show task" do
  #   get task_url(@task)
  #   assert_response :success
  # end

  # test "should update task" do
  #   patch task_url(@task), params: { task: {  } }
  #   assert_redirected_to task_url(@task)
  # end

  # test "should destroy task" do
  #   assert_difference("Task.count", -1) do
  #     delete task_url(@task)
  #   end

  #   assert_redirected_to tasks_url
  # end
end
