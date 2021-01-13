require "test_helper"

module EnglishRoutes
  class HomeControllerTest < ActionDispatch::IntegrationTest
    def en_root_path
      home_root_path :en
    end

    def en_root_url
      home_root_url :en
    end

    test "root should get show" do
      assert_routing en_root_path, controller: "home", action: "show", locale: "en"
      get en_root_url
      assert_template "home/show"
      assert_response :success
    end

    test "root should display the contact form" do
      get en_root_url

      assert_template partial: "home/contact", count: 1

      assert_select "div.contact-us", count: 1

      assert_select "div.contact-us" do |wrappers|
        assert_equal 1, wrappers.size

        assert_select wrappers.first, ".mdc-card", count: 1

        assert_select wrappers.first, ".mdc-card" do |cards|
          card = cards.first

          assert_select card, ".mdc-card__header.mdc-card--filled h2.mdc-typography--headline6",
            count: 1,
            message: "Request a Free Consultation"

          assert_select card, ".mdc-card__body", count: 1

          assert_select card, ".mdc-card__body" do |bodies|
            card_body = bodies.first

            assert_select card_body, "form", count: 1

            assert_template partial: "shared/contact_form", count: 1
          end
        end
      end
    end
  end
end
