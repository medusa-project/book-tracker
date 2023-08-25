require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest

  setup do 
    OmniAuth.config.test_mode = true 
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
      provider:'google',
      uid:'admin@email.com',
      info: {
        name:'admin',
        email: '123@admin.com'
        }
      })
  end
    
  test "should create session" do 

    post '/auth/google/callback'
    assert_redirected_to root_url 
    follow_redirect!

    assert_response :redirect 
  end
  
end


