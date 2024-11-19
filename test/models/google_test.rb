require 'test_helper'
require 'mocha/minitest'

class GoogleTest < ActiveSupport::TestCase
  def setup
    @inventory_key = 'test_inventory_key'
    @google = Google.new(@inventory_key)
    @task = Task.create!(name: 'Google Test Task', service: Service::GOOGLE, status: Task::Status::SUBMITTED)
    Book.delete_all  

    @gb = Book.create!(bib_id: 1, obj_id: 'test_id_1', exists_in_google: false)
    @gb2 = Book.create!(bib_id: 2, obj_id: 'test_id_2', exists_in_google: false)
  end

  def teardown 
    @task.destroy 
    Book.delete_all 
  end

  test 'check should raise error if another check is in progress' do
    Task.create!(name: 'Running Task', service: Service::GOOGLE, status: Task::Status::RUNNING)
    assert_raises(RuntimeError, 'Another Google check is in progress.') do
      @google.check
    end
  end

  test 'check should create a new task if none is provided' do 
    mock_response = Struct.new(:body).new("test_id_1\ttest_date\n" * 2)
    mock_store = mock('TempStore')
    mock_store.stubs(:get_object).returns(mock_response)
    mock_store.stubs(:delete_object).with(bucket: 'book-tracker-temp-test', key: @inventory_key).returns(nil)
    
    TempStore.stubs(:instance).returns(mock_store)

    assert_difference 'Task.count', 1 do 
      @google.check 
    end
  end

    test 'check should update the database with items found' do 
      mock_response = Struct.new(:body).new("test_id_1\ttest_date\n" * 2)
      mock_store = mock('TempStore')
      mock_store.stubs(:get_object).returns(mock_response)
      mock_store.stubs(:delete_object).with(bucket: 'book-tracker-temp-test', key: @inventory_key).returns(nil)
      
      TempStore.stubs(:instance).returns(mock_store)

      @google.check

      @gb.reload
      @gb2.reload 

      assert_equal 1, Book.where(exists_in_google: true).count
      assert @gb.exists_in_google 
      assert !@gb2.exists_in_google
    end

    # mock_store = Minitest::Mock.new 
    # mock_store.expect :get_object, mock_response, [{ bucket: 'book-tracker-temp-test', key: @inventory_key }]
    # mock_store.expect :get_object, mock_response, [{ bucket: 'book-tracker-temp-test', key: @inventory_key }]
    # mock_store.expect :delete_object, nil, [{ bucket: 'book-tracker-temp-test', key: @inventory_key }]

    # mock_store.expect :get_object, mock_response do |args|
    #   puts "get_object called with: #{args}"
    #   args.is_a?(Hash) && args[:bucket] == 'book-tracker-temp-test' && args[:key] == @inventory_key
    # end
    # mock_store.expect :delete_object, nil do |args|
    #   args.is_a?(Hash) && args[:bucket] == 'book-tracker-temp-test' && args[:key] == @inventory_key
    # end

  #   TempStore.stub :instance, mock_store do
  #     assert_difference 'Task.count', 1 do 
  #       @google.check 
  #     end
  #   end
  #   mock_store.verify 
  # end


end