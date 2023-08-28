require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
# do I need this setup if I have the auth hash setup in the test_helper?
  # setup do 
  #   OmniAuth.config.test_mode = true 
  #   OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
  #     provider:'google',
  #     uid:'admin@email.com',
  #     info: {
  #       name:'admin',
  #       email: '123@admin.com'
  #       }
  #     })
  # end

  test "should redirect to books_path if sign in succeeds" do 
    skip()
    # assert_redirected_to books_path
    # follow_redirect! 
    # assert_response :redirect
  end
    
  test "should redirect to root path if sign in fails" do 

    post '/auth/:provider/callback'
  
    assert_redirected_to root_url
    follow_redirect!

    assert_response :redirect 
    
  end
end


