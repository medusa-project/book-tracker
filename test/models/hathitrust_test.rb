require 'test_helper'
require 'mocha/minitest'

class HathitrustTest < ActiveSupport::TestCase
  def setup
    @hathitrust = Hathitrust.new
    @task = Task.create!(name: 'Test Task', service: Service::HATHITRUST, status: Task::Status::SUBMITTED)
  end

  test 'check_authorized? returns true when no running tasks' do 
    assert Hathitrust.check_authorized? 
  end

  test 'check_authorized? returns false when there are running tasks' do 
    Task.create!(name: 'Test Task', service: Service::HATHITRUST, status: Task::Status::RUNNING)
    assert !Hathitrust.check_authorized?
  end

  test 'check updates book records correctly' do 
    book = Book.create!(obj_id: 'test_obj_id', exists_in_hathitrust: false, hathitrust_access: 'old_access', hathitrust_rights: 'old_rights')

    Hathitrust.any_instance.stubs(:find_hathifile_url).returns('http://example.com/hathifile')
    Hathitrust.any_instance.stubs(:download_hathifile).returns('test/fixtures/files/fake_hathifile.txt')
    File.stubs(:foreach).returns(["test_obj_id\tnew_access\tnew_rights\t\t\tUIU"])
    File.stubs(:open).returns(["test_obj_id\tnew_access\tnew_rights\t\t\tUIU"])


      @hathitrust.check(@task)

      book.reload 

      assert book.exists_in_hathitrust
      assert_equal 'new_access', book.hathitrust_access 
      assert_equal 'new_rights', book.hathitrust_rights
  end

  test 'selenium webdriver correctly scrapes the HathiTrust page' do 
    # Mock the Selenium WebDriver
    driver = mock('driver')
    navigation = mock('navigation')
    Selenium::WebDriver.stubs(:for).returns(driver)
    driver.stubs(:navigate).returns(navigation)
    navigation.stubs(:to).with('https://www.hathitrust.org/hathifiles')
    driver.stubs(:find_elements).returns([
      stub(text: 'hathi_full_20250501.txt', '[]' => 'https://www.hathitrust.org/hathifiles/'),
    ])
    driver.stubs(:quit)

    url = @hathitrust.send(:find_hathifile_url, @task)
    assert_equal 'https://www.hathitrust.org/hathifiles/', url
  end
end