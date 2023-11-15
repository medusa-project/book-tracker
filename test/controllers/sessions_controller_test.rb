require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest

  test "should redirect to books_path if sign in succeeds" do
    skip()
    skip # TODO: figure out how to test this
    post '/auth/:provider/callback'

    log_in
    
    assert_redirected_to books_path
    follow_redirect! 

    assert_response :success
  end
    
  test "should redirect to root path if sign in fails" do 
    skip()
    post '/auth/:provider/callback'
  
    assert_redirected_to root_url
    follow_redirect!

    assert_response :redirect 
  end

  test "should logout" do 
    delete '/signout'

    assert_redirected_to root_url 
    follow_redirect!

    assert_response :redirect
  end
end


