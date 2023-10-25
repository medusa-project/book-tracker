require "test_helper"

class SamlTest < ActionDispatch::IntegrationTest

  test "/auth/saml/metadata returns HTTP 200" do
    get "/auth/saml/metadata"
    assert_response :ok
  end

end
