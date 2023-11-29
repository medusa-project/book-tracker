require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = tasks(:one)
  end

  test "should get tasks" do
    get tasks_url

    assert_response :success
  end

  test "should prepare to import marcxml records" do
    post import_path(@task)

    assert_response :success
    assert_equal 200, response.status
  end

  test "should conduct a Google check" do 

    post check_google_url 

    assert_equal 200, response.status
  end

  test "should redirect back to '/check-google' after conducting Google check" do 

    post check_google_url 

    assert_equal "/check-google", request.path 
  end
end
