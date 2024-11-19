require 'test_helper'
require 'minitest/mock'

class InternetArchiveTest < ActiveSupport::TestCase
  def setup
    @internet_archive = InternetArchive.new 
    @task = Task.create!(name: 'Test Task', service: Service::INTERNET_ARCHIVE, status: Task::Status::SUBMITTED)
    Book.delete_all

    Book.create!(bib_id: 1, ia_identifier: 'test_id_1', exists_in_internet_archive: false)
    Book.create!(bib_id: 2, ia_identifier: 'test_id_2', exists_in_internet_archive: false)
  end

  def teardown 
    @task.destroy 
    Book.delete_all
  end

  test 'check should update the database with items found' do
    mock_api_results = Nokogiri::XML('<result numFound="2"><doc><str>test_id_1</str></doc><doc><str>test_id_2</str></doc></result>')
    
    @internet_archive.stub :get_api_results, mock_api_results do
      @internet_archive.check(@task)
      
      # Verify that the task status is updated to succeeded
      @task.reload
      assert_equal Task::Status::SUCCEEDED, @task.status

      # Verify that the database is updated with the items found
      assert_equal 2, Book.where(exists_in_internet_archive: 'true').count

      books = Book.where(exists_in_internet_archive: 'true')
      books.each { |book| puts book.inspect }

      assert Book.exists?(ia_identifier: 'test_id_1')
      assert Book.exists?(ia_identifier: 'test_id_2')
      # assert Book.exists?(ia_identifier: 'test_id_1')
      # assert Book.exists?(ia_identifier: 'test_id_2')
    end
  end

  test 'check should raise error if another check is in progress' do 
    Task.create!(name: 'Running Task', service: Service::INTERNET_ARCHIVE, status: Task::Status::RUNNING)
    assert_raises(RuntimeError, 'Another Internet Archive check is in progress.') do 
      @internet_archive.check 
    end
  end


  test 'check should update the task status to succeeded in completion' do
    mock_api_results = Nokogiri::XML('<result numFound="1"><doc><str>test_id</str></doc></result>')
    @internet_archive.stub :get_api_results, mock_api_results do 
      @internet_archive.stub :set_existing, nil do 
        @internet_archive.check(@task)
        @task.reload 
        assert_equal Task::Status::SUCCEEDED, @task.status
      end
    end
  end
end