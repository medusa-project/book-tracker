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


# In BooksController.index(), there are four formats in the respond_to block: 
# HTML, CSV, JSON, and XML. 
# We should have tests for each of these that check for an HTTP 200 response, 
# check the Content-Type header, 
# and ideally check that the response body looks like valid HTML/CSV/JSON/XML.

test "return http 200 status request for HTML format" do
  
    get books_path(format: :html)

    assert_response :success
    assert_equal 200, response.status 
end

test "return 'text/html; charset=utf-8' for Content-Type" do 

    get books_path(format: :html)

    assert_equal "text/html; charset=utf-8", response.header['Content-Type']
end

test "return http 200 status request for XML format" do

    get books_path(format: :xml)

    assert_response :success
    assert_equal 200, response.status
  end

  test "return 'application/xml' for response header Content-Type" do 
    
    get books_path(format: :xml)

    assert_equal "application/xml", response.header['Content-Type']
  end

  # test "return http 200 status request for JSON format" do 
  # end

  test "return http 200 status request for CSV format" do 

    get books_path(format: :csv)

    assert_response :success 
    assert_equal 200, response.status 
  end

  test "return 'text/csv' for response header Content-Type" do 

    get books_path(format: :csv)

    assert_equal "text/csv", response.header['Content-Type']
  end
end