require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:one)
  end

  test "should return http 200 status request for all books" do
    get books_url

    assert_response :success
    assert_equal 200, response.status 
  end

  test "return http 200 status request for any particular book" do
    get book_url(@book)

    assert_response :success
    assert_equal 200, response.status 
  end

  test "returns book data in json format" do 
    get book_url(@book, format: :json)
    
    json_response = JSON.parse(@response.body, symbolize_names: true)

    assert_includes json_response.keys, :id
    assert_equal 980190962, json_response[:id]
  end
end
