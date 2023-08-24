require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  # setup do 
  #   OmniAuth.config.test_mode = true 
  #   auth_hash = { 'provider' => 'google',
  #                 'uid' => '34',
  #                 'info' => {
  #                     'name' => 'admin',
  #                     'email' => '123@admin.com',
  #                   }
  #               }
  #   OmniAuth.config.add_mock(:google, auth_hash)
  #   user.username == 'admin'
  # end
  
  test "should create session" do 
    skip()
    post sessions_url 
  end
end

  # test "should destroy session" do
  #   assert_difference("Session.count", -1) do
  #     delete session_url(@session)
  #   end

  #   assert_redirected_to sessions_url
  # end
