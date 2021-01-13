require 'test_helper'

class ApplicationLayoutTest < ActionView::TestCase
  test "application layout renders header" do
    render layout: "layouts/application", html: ""

    assert_template partial: "layouts/top_bar", count: 1
  end
end
