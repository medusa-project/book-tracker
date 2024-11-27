require 'test_helper'
require 'minitest/mock'

class InternetArchiveTest < ActiveSupport::TestCase
  def setup
    @internet_archive = InternetArchive.new 
    @task = Task.create!(name: 'Test Task', service: Service::INTERNET_ARCHIVE, status: Task::Status::SUBMITTED)
    Book.delete_all

    Book.create!(bib_id: 1, ia_identifier: 'test_id_1', exists_in_internet_archive: false)
    Book.create!(bib_id: 2, ia_identifier: 'test_id_2', exists_in_internet_archive: false)
    Book.create!(bib_id: 3, ia_identifier: 'test_id_3', exists_in_internet_archive: true)
    Book.create!(bib_id: 4, ia_identifier: 'test_id_4', exists_in_internet_archive: true)
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

      books = Book.where(exists_in_internet_archive: true)
      books.each do |book|
        assert book.exists_in_internet_archive
      end

      # Verify that the database is updated with the items found
      assert_equal 4, Book.where(exists_in_internet_archive: true).count
    end
  end

  # verify database changes
  test 'set_existing updates the book objects correctly' do 

    Book.delete_all 

    batch = ["test_id_1", "test_id_2"]
    bk1 = Book.create!(bib_id: 1, ia_identifier: 'test_id_1', exists_in_internet_archive: false)
    bk2 = Book.create!(bib_id: 2, ia_identifier: 'test_id_2', exists_in_internet_archive: false)

    assert_equal 0, Book.where(exists_in_internet_archive: true).count

    @internet_archive.send(:set_existing, batch)

    bk1.reload 
    bk2.reload 

    assert_equal 2, Book.where(exists_in_internet_archive: true).count

    assert_equal true, bk1.exists_in_internet_archive
    assert_equal true, bk2.exists_in_internet_archive
    assert Book.exists?(ia_identifier: 'test_id_1', exists_in_internet_archive: true)
    assert Book.exists?(ia_identifier: 'test_id_2', exists_in_internet_archive: true)
  end

  test 'set_existing calls bulk_update with correct arguments' do 
    Book.delete_all 

    batch = ["test_id_1", "test_id_2"]

    Book.stub(:bulk_update, ->(batch_arg, column, new_value, where_column) {
      assert_equal ['test_id_1', 'test_id_2'], batch_arg 
      assert_equal 'exists_in_internet_archive', column 
      assert_equal 'true', new_value 
      assert_equal 'ia_identifier', where_column 
    }) do 
      @internet_archive.send(:set_existing, batch)
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
      @internet_archive.stub :set_existing, ->(batch) { Rails.logger.debug("Batch set: #{batch.inspect}") } do 
        @internet_archive.check(@task)
        @task.reload 
        assert_equal Task::Status::SUCCEEDED, @task.status
      end
    end
  end
end