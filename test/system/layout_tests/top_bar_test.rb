require "application_system_test_case"

module LayoutTests
  class TopBarTest < ApplicationSystemTestCase
    ELEMENT_CLICK_INTERCEPTED =
      Selenium::WebDriver::Error::ElementClickInterceptedError

    test "should exist" do
      I18n.available_locales.each do |locale|
        I18n.with_locale(locale) do
          visit home_root_url(locale)

          assert_has_top_bar(text: I18n.t(:title))
        end
      end
    end
  end
end
