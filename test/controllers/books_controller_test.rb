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

  test "can filter by oclc number" do 
    @b6 = books(:six)
    @b5 = books(:five)
    @b4 = books(:four)

    @books = [@b4, @b5, @b6]

    query = "#{@b6.oclc_number}\n#{@b5.oclc_number}"

    get books_url(q: query, format: :json)

    response_body = JSON.parse(response.body)

    assert_equal 2, response_body['numResults']
    assert_equal @b6.oclc_number, response_body['results'][0]['oclc_number']
    assert_equal @b5.oclc_number, response_body['results'][1]['oclc_number']
  end

  test "can filter by object_id" do 
    @b6 = books(:six)
    @b5 = books(:five)
    @b4 = books(:four)

    @books = [@b4, @b5, @b6]

    query = "#{@b6.obj_id}\n#{@b5.obj_id}"

    get books_url(q: query, format: :json)

    response_body = JSON.parse(response.body)

    assert_equal @b6.obj_id, response_body['results'][0]['obj_id']
    assert_equal @b5.obj_id, response_body['results'][1]['obj_id']
  end

  test "can filter by bib_id" do 
    @b6 = books(:six)
    @b5 = books(:five)
    @b4 = books(:four)

    @books = [@b4, @b5, @b6]

    query = "#{@b6.bib_id}\n#{@b5.bib_id}"
    
    get books_url(q: query, format: :json)

    response_body = JSON.parse(response.body)

    assert_equal @b6.bib_id, response_body['results'][0]['bib_id']
    assert_equal @b5.bib_id, response_body['results'][1]['bib_id']
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

  test "return http 200 status request for HTML format" do
  
    get books_path(format: :html)

    assert_response :success
    assert_equal 200, response.status 
  end
  
  test "return 'text/html; charset=utf-8' for Content-Type" do 
    
    get books_path(format: :html)
    
    assert_equal "text/html; charset=utf-8", response.header['Content-Type']
  end

  test "response body is valid HTML" do 
    
    get books_path(format: :html)

    valid_html = Nokogiri::HTML.parse(response.body)

    assert_equal valid_html.children[0].name, "html"
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

  test "response body is valid XML format" do 

    get books_path(format: :xml)

    valid_xml = Nokogiri::XML.parse(response.body)

    assert_equal valid_xml.children[0].children[1].name, "collection"
  end

  test "return http 200 status request for JSON format" do 

    get books_path(format: :json)

    assert_response :success
    assert_equal 200, response.status
  end

  test "return 'application/json' for response header Content-Type" do 
    
    get books_path(format: :json)

    assert_equal "application/json; charset=utf-8", response.header['Content-Type']
  end

  test "response body is valid JSON format" do 

    get books_path(format: :json)

    valid_json = JSON.parse(response.body)

    assert_equal valid_json["results"][0]["id"], 868521 
    assert_equal valid_json.class, Hash 
  end

  test "return http 200 status request for CSV format" do 

    get books_path(format: :csv)

    assert_response :success 
    assert_equal 200, response.status 
  end

  test "return 'text/csv' for response header Content-Type" do 

    get books_path(format: :csv)

    assert_equal "text/csv", response.header['Content-Type']
  end

  test "response body is valid CSV format" do 
    
    get books_path(format: :csv)

    csv = CSV.new(response.body, headers: true)
    csv.each do |row|
      row 
    end
    
    assert_equal ["Bib ID", "Medusa ID", "OCLC Number", "Object ID", "Title", "Author", "Volume", "Date", "IA Identifier", "HathiTrust Handle", "Exists in HathiTrust", "Exists in IA", "Exists in Google"], csv.headers
    assert_equal csv.class, CSV
  end
end