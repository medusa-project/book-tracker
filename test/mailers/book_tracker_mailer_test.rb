require 'test_helper'

class BookTrackerMailerTest < ActionMailer::TestCase

  tests BookTrackerMailer

  # error()

  test "error() sends the expected email" do
    email = BookTrackerMailer.error("Something broke").deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    config = ::Configuration.instance
    assert_equal [BookTrackerMailer::NO_REPLY_ADDRESS], email.reply_to
    assert_equal [config.admin_email], email.to
    assert_equal "[TEST: Book Tracker] System Error", email.subject
    assert_equal "Something broke\r\n\r\n", email.body.raw_source
  end

  # test()

  test "test() sends the expected email" do
    recipient = "user@example.edu"
    email = BookTrackerMailer.test(recipient).deliver_now
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [Configuration.instance.admin_email], email.from
    assert_equal [recipient], email.to
    assert_equal "[TEST: Book Tracker] Hello from Book Tracker", email.subject

    assert_equal render_template("test.txt"), email.text_part.body.raw_source
    assert_equal render_template("test.html"), email.html_part.body.raw_source
  end


  private

  def render_template(fixture_name, vars = {})
    text = read_fixture(fixture_name).join
    vars.each do |k, v|
      text.gsub!("{{{#{k}}}}", v)
    end
    text
  end

end
