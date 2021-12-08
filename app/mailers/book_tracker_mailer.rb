# frozen_string_literal: true

class BookTrackerMailer < ApplicationMailer
  # This address is not arbitrary;
  # see https://answers.uillinois.edu/illinois/page.php?id=47888
  NO_REPLY_ADDRESS = "no-reply@illinois.edu"

  default from: "Book Tracker <#{::Configuration.instance.admin_email}>"

  def error(error_text)
    @error_text = error_text
    mail(reply_to: NO_REPLY_ADDRESS,
         to:       ::Configuration.instance.admin_email,
         subject:  "#{subject_prefix} System Error")
  end

  ##
  # Used to test email delivery. See also the `mail:test` rake task.
  #
  def test(recipient)
    mail(to: recipient, subject: "#{subject_prefix} Hello from Book Tracker")
  end


  private

  def subject_prefix
    "[#{Rails.env.to_s.upcase}: Book Tracker]"
  end
end
