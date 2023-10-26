require "test_helper"
require "pry"

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

    # i tried using the existing sample.xml fixture file but since the response.body isn't formatted I couldn't assert the two as equal
    valid_xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<export>\n<record> <leader>00968nam a2200229 i 4500</leader> <controlfield tag=\"001\\\">272087</controlfield> <controlfield tag=\"005\\\">20020415161422.0</controlfield> <controlfield tag=\"008\\\">771215s1977dcuf00010engd</controlfield> <datafield tag=\"035\\\" ind1=\" \\\" ind2=\" \\\"> <subfield code=\"a\\\">(OCoLC)ocm03493895</subfield> </datafield> <datafield tag=\"035\\\" ind1=\" \\\" ind2=\" \\\"> <subfield code=\"9\\\">ABC-6433</subfield> </datafield> <datafield tag=\"040\\\" ind1=\" \\\" ind2=\" \\\"> <subfield code=\"a\\\">GPO</subfield> <subfield code=\"c\\\">GPO</subfield> <subfield code=\"d\\\">VRC</subfield> <subfield code=\"d\\\">UIU</subfield> <subfield code=\"d\\\">m.c.2</subfield> </datafield> <datafield tag=\"074\\\" ind1=\" \\\" ind2=\" \\\"> <subfield code=\"a\\\">502-A-2</subfield> </datafield> <datafield tag=\"086\\\" ind1=\"0\\\" ind2=\" \\\"> <subfield code=\"a\\\">HE 23.3102:T 34</subfield> </datafield> <datafield tag=\"110\\\" ind1=\"2\\\" ind2=\"0\\\"> <subfield code=\"a\\\">National Clearinghouse on Aging.</subfield> </datafield> <datafield tag=\"245\\\" ind1=\"1\\\" ind2=\"0\\\"> <subfield code=\"a\\\">National Clearinghouse on Aging thesaurus.</subfield> </datafield> <datafield tag=\"250\\\" ind1=\" \\\" ind2=\" \\\">\\ <subfield code=\"a\\\">2d ed., July 1977.</subfield> </datafield> <datafield tag=\"260\\\" ind1=\"0\\\" ind2=\" \\\"> <subfield code=\"a\\\">Washington :</subfield> <subfield code=\"b\\\">Dept. of Health, Education, and Welfare, Office of Human Development Services, Administation on Aging, National Clearinghouse on Aging,</subfield> <subfield code=\"c\\\">1977.</subfield> </datafield> <datafield tag=\"300\\\" ind1=\" \\\" ind2=\" \\\"> <subfield code=\"a\\\"> 137 p. in various pagings ;</subfield> <subfield code=\"c\\\">28 cm.</subfield> </datafield> <datafield tag=\"490\\\" ind1=\"0\\\" ind2=\" \\\"> <subfield code=\"a\\\">United States.  Dept. of Health, Education, and Welfare. DHEW publication ;  no. (OHDS) 78-20087</subfield> </datafield> <datafield tag=\"500\\\" ind1=\" \\\" ind2=\" \\\"> <subfield code=\"a\\\">Prepared by Documentation Associates Information Services Incorporated under contract no. HEW 105-76-3000.</subfield> </datafield> <datafield tag=\"650\\\" ind1=\" \\\" ind2=\"0\\\"> <subfield code=\"a\\\">Gerontology</subfield> <subfield code=\"x\\\">Terminology.</subfield> </datafield> <datafield tag=\"650\\\" ind1=\" \\\" ind2=\"0\\\"> <subfield code=\"a\\\">Aging</subfield> <subfield code=\"x\\\">Terminology.</subfield> </datafield> <datafield tag=\"955\\\" ind1=\" \\\" ind2=\" \\\"> <subfield code=\"a\\\">UIU</subfield> <subfield code=\"b\\\">30112048976390</subfield> <subfield code=\"c\\\">472411</subfield> <subfield code=\"d\\\">Stacks</subfield> <subfield code=\"e\\\">301.435014 N213N1977</subfield> <subfield code=\"f\\\">2</subfield> <subfield code=\"g\\\">am</subfield> </datafield> </record>\nText\nMyText\nMyText\nMyText\nMyText\n</export>"
    
    assert_equal valid_xml, response.body
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
    skip()
  end

end