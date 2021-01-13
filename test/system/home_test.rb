require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "should determine locale as root" do
    visit root_url

    assert_title "Solar Energy Pros"
  end

  test "should show english home as 'en' root" do
    visit home_root_url(:en)

    assert_title "Solar Energy Pros"
  end

  test "should show spanish home as 'es' root" do
    visit home_root_url(:es)

    assert_title "Pros de la Energía Solar"
  end
end
