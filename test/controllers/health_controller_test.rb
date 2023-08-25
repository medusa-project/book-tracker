require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  # setup do
  #   @health = healths(:one)
  # end

  test "should get health check" do
    get health_url

    assert_response :success
    assert_equal 'OK', response.body 
  end

  test "should return a server error message if there is a 500 error" do 
    get error_url 

    assert_response :internal_server_error
    assert_equal '500 Internal Server Error', response.body 
  end
end
