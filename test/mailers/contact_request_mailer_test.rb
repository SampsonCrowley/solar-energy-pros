require 'test_helper'

class ContactRequestMailerTest < ActionMailer::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "received" do
    email =
      ContactRequestMailer.
        with(
          name: "Test Received Name",
          email: "test@received.com",
          phone: "1234567890",
          street: "1234 Road Somewhere",
          city: "Los Angeles",
          zip: "43210",
          estimated_electric_bill: "$50-100",
          estimated_credit_score: "700+",
          message: "Test Received Message"
        ).
        received

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "info@solarenergypros.online" ], email.from
    assert_equal [ "test@received.com" ], email.to
    assert_equal "Request Received", email.subject

    read_fixture("received_en_html").each do |line|
      assert_match line.strip, email.html_part.body.to_s
    end

    assert_equal read_fixture("received_en_text").join.gsub(/\n\s+\n/m, "\n").strip, get_text_body_content(email)
  end

  test "received spanish" do
    email =
      ContactRequestMailer.
        with(
          locale: "es",
          name: "Test Received Name",
          email: "test@received.com",
          phone: "1234567890",
          street: "1234 Road Somewhere",
          city: "Los Angeles",
          zip: "43210",
          estimated_electric_bill: "$50-100",
          estimated_credit_score: "700+",
          message: "Test Received Message"
        ).
        received

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "info@solarenergypros.online" ], email.from
    assert_equal [ "test@received.com" ], email.to
    assert_equal "Solicitud Recibida", email.subject

    read_fixture("received_es_html").each do |line|
      assert_match line.strip, email.html_part.body.to_s
    end

    assert_equal read_fixture("received_es_text").join.gsub(/\n\s+\n/m, "\n").strip, get_text_body_content(email)
  end

  test "submission" do
    email =
      ContactRequestMailer.
        with(
          name: "Test Submitted Name",
          email: "test@submission.com",
          phone: "1234567890",
          street: "1234 Road Somewhere",
          city: "Los Angeles",
          zip: "43210",
          estimated_electric_bill: "$50-100",
          estimated_credit_score: "700+",
          message: "Test Submitted Message"
        ).
        submission

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "info@solarenergypros.online" ], email.from
    assert_equal [ "contact-request@solarenergypros.online" ], email.to
    assert_equal "Contact Request Submitted: Test Submitted Name<test@submission.com>", email.subject

    read_fixture("submission_en_html").each do |line|
      assert_match line.strip, email.html_part.body.to_s
    end

    assert_equal read_fixture("submission_en_text").join.gsub(/\n\s+\n/m, "\n").strip, get_text_body_content(email)
  end

  test "submission spanish" do
    email =
      ContactRequestMailer.
        with(
          locale: "es",
          name: "Test Submitted Name",
          email: "test@submission.com",
          phone: "1234567890",
          street: "1234 Road Somewhere",
          city: "Los Angeles",
          zip: "43210",
          estimated_electric_bill: "$50-100",
          estimated_credit_score: "700+",
          message: "Test Submitted Message"
        ).
        submission

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "info@solarenergypros.online" ], email.from
    assert_equal [ "contact-request@solarenergypros.online" ], email.to
    assert_equal "Contact Request Submitted: Test Submitted Name<test@submission.com>", email.subject

    read_fixture("submission_es_html").each do |line|
      assert_match line.strip, email.html_part.body.to_s
    end

    assert_equal read_fixture("submission_es_text").join.gsub(/\n\s+\n/m, "\n").strip, get_text_body_content(email)
  end

  private
    def get_text_body_content(email)
      email.text_part.body.to_s.gsub(/\r\n/m, "\n").gsub(/\n\s+\n/, "\n").strip
    end

end
