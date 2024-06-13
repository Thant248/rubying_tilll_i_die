require "test_helper"

class V1::RoomsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get v1_rooms_show_url
    assert_response :success
  end
end
