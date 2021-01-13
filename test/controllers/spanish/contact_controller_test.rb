require 'test_helper'

module SpanishRoutes
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
        name: "Nombre",
        phone: "Teléfono",
        email: "Correo Electrónico",
        street: "Dirección",
        city: "Ciudad",
        zip: "Código Postal",
        estimated_electric_bill: "Factura de Electricidad Mensual Estimada",
        estimated_credit_score: "Puntaje de Crédito Estimado",
        message: "¿Algo que le gustaría que supiéramos? (Opcional)",
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

    def es_contact_url
      contact_url :es
    end

    test "should get root" do
      get es_contact_url
      assert_response :success
      assert_renders_form
    end

    test "should return an unprocessable error when empty" do
      post es_contact_url
      assert_response :unprocessable_entity
      assert_renders_form errors: (%i[ name email street city zip estimated_electric_bill estimated_credit_score ].map {|attr| "#{labels[attr]} es un campo obligatorio, por favor proporcione antes de enviar"})
    end

    test "should return an unprocessable error when email empty" do
      post es_contact_url, params: { contact: valid_params.without(:email) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Correo Electrónico es un campo obligatorio, por favor proporcione antes de enviar" ]
    end

    test "should return an unprocessable error when email invalid" do
      post es_contact_url, params: { contact: valid_params.merge(email: "invalid@email") }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Formato de correo inválido; proporcione un correo electrónico válido" ]
    end

    test "should return an unprocessable error when zip empty" do
      post es_contact_url, params: { contact: valid_params.without(:zip) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Código Postal es un campo obligatorio, por favor proporcione antes de enviar" ]
    end

    test "should return an unprocessable error when zip invalid" do
      post es_contact_url, params: { contact: valid_params.merge(zip: "invalid@zip") }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Formato de código postal no válido; proporcione un código postal válido" ]
    end

    test "should return an unprocessable error when name empty" do
      post es_contact_url, params: { contact: valid_params.without(:name) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Nombre es un campo obligatorio, por favor proporcione antes de enviar" ]
    end

    test "should return an unprocessable error when street empty" do
      post es_contact_url, params: { contact: valid_params.without(:street) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Dirección es un campo obligatorio, por favor proporcione antes de enviar" ]
    end

    test "should return an unprocessable error when city empty" do
      post es_contact_url, params: { contact: valid_params.without(:city) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Ciudad es un campo obligatorio, por favor proporcione antes de enviar" ]
    end

    test "should return an unprocessable error when estimated_electric_bill empty" do
      post es_contact_url, params: { contact: valid_params.without(:estimated_electric_bill) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Factura de Electricidad Mensual Estimada es un campo obligatorio, por favor proporcione antes de enviar" ]
    end

    test "should return an unprocessable error when estimated_credit_score empty" do
      post es_contact_url, params: { contact: valid_params.without(:estimated_credit_score) }
      assert_response :unprocessable_entity
      assert_renders_form errors: [ "Puntaje de Crédito Estimado es un campo obligatorio, por favor proporcione antes de enviar" ]
    end
  end
end
