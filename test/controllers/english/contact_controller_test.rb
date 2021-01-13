require 'test_helper'

module EnglishRoutes
  class ContactControllerTest < ActionDispatch::IntegrationTest
    def valid_params
      {
        name: "John",
        email: "email@email.com",
        message: "HELP!!!",
        street: "1234 Road Somewhere",
        city: "Los Angeles",
        zip: "43210",
        estimated_electric_bill: "$50-100",
        estimated_credit_score: "700+"
      }
    end

    def labels
      {
        name: "Name",
        phone: "Phone",
        email: "Email",
        street: "Street Address",
        city: "City",
        zip: "Zip",
        estimated_electric_bill: "Estimated Monthly Electric Bill",
        estimated_credit_score: "Estimated Credit Score",
        message: "Anything you would like us to know? (Optional)"
      }
    end

    def assert_renders_form(errors: nil, success: nil)
      assert_select "form#contact_form" do |forms|
        assert_equal 1, forms.size
        form = forms.first
        if errors
          assert_select form, "#main_errors" do |error_banners|
            assert_equal 1, error_banners.size
            banner = error_banners.first
            case errors
            when String
              assert_select banner, "p.error-message", errors
            when Array, Set
              assert_select banner, "p.error-message", count: errors.size
              errors.each do |error|
                assert_select banner, "p.error-message", error
              end
            else
              raise "Invalid Errors to Match"
            end
          end
        elsif success
          assert_select form, "#success_message", count: 1
          assert_select form, "#success_message" do |success_banner|
            banner = success_banner.first
            assert_select banner, "p.success-message", "Your request has been sent!"
          end
        end
      end
    end

    def en_contact_url
      contact_url :en
    end

    test "should get root" do
      get en_contact_url
      assert_response :success
      assert_renders_form
    end

    test "should return an unprocessable error when empty" do
      post en_contact_url
      assert_response :unprocessable_entity
      assert_renders_form errors: (%i[ name email street city zip estimated_electric_bill estimated_credit_score ].map {|attr| "#{labels[attr]} is a required field, please provide it before submitting"})
    end

    test "should return an unprocessable error when email empty" do
      post en_contact_url, params: { contact: valid_params.without(:email) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Email is a required field, please provide it before submitting" ]
    end

    test "should return an unprocessable error when email invalid" do
      post en_contact_url, params: { contact: valid_params.merge(email: "invalid@email") }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Invalid email format; please provide a valid email" ]
    end

    test "should return an unprocessable error when zip empty" do
      post en_contact_url, params: { contact: valid_params.without(:zip) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Zip is a required field, please provide it before submitting" ]
    end

    test "should return an unprocessable error when zip invalid" do
      post en_contact_url, params: { contact: valid_params.merge(zip: "invalid@zip") }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Invalid zip format; please provide a valid zip code" ]
    end

    test "should return an unprocessable error when name empty" do
      post en_contact_url, params: { contact: valid_params.without(:name) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "#{labels[:name]} is a required field, please provide it before submitting" ]
    end

    test "should return an unprocessable error when street empty" do
      post en_contact_url, params: { contact: valid_params.without(:street) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "#{labels[:street]} is a required field, please provide it before submitting" ]
    end

    test "should return an unprocessable error when city empty" do
      post en_contact_url, params: { contact: valid_params.without(:city) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "#{labels[:city]} is a required field, please provide it before submitting" ]
    end

    test "should return an unprocessable error when estimated_electric_bill empty" do
      post en_contact_url, params: { contact: valid_params.without(:estimated_electric_bill) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "#{labels[:estimated_electric_bill]} is a required field, please provide it before submitting" ]
    end

    test "should return an unprocessable error when estimated_credit_score empty" do
      post en_contact_url, params: { contact: valid_params.without(:estimated_credit_score) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "#{labels[:estimated_credit_score]} is a required field, please provide it before submitting" ]
    end

    test "should return success when valid" do
      assert_enqueued_emails 2 do
        post en_contact_url, params: { contact: valid_params }
        assert_response :success
        assert_renders_form success: true
      end
    end
  end
end
