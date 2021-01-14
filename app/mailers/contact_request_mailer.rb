class ContactRequestMailer < ApplicationMailer
  def received
    with_locale do
      @email = params[:email]
      @message = params[:message]
      @name = params[:name]

      mail to: @email, subject: t(:request_subject), skip_filter: true
    end
  end

  def submission
    with_locale do
      @name = params[:name]
      @email = params[:email]
      @phone = params[:phone]
      @street = params[:street]
      @city = params[:city]
      @zip = params[:zip]
      @estimated_electric_bill = params[:estimated_electric_bill]
      @estimated_credit_score = params[:estimated_credit_score]
      @message = params[:message]

      mail to: "contact-request@solarenergypros.online", subject: "Contact Request Submitted: #{@name}<#{@email}>"
    end
  end
end
