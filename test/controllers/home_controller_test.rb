require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root should determine locale" do
    assert_routing root_path, controller: "home", action: "detect_language"
    get root_url
    assert_redirected_to "#{home_root_url}/"
    assert_response :redirect
  end
end
