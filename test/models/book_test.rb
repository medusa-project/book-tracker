require 'test_helper'
require 'minitest/mock'


class BookTest < ActiveSupport::TestCase

  test 'bulk_update works' do
    b1 = books(:one)
    b2 = books(:two)
    b3 = books(:three)
    assert !b1.exists_in_google and !b2.exists_in_google and !b3.exists_in_google

    batch = [b1.obj_id, b2.obj_id]
    Book.bulk_update(batch, 'exists_in_google', 'true', 'obj_id')
    b1.reload
    b2.reload
    b3.reload
    assert b1.exists_in_google and b2.exists_in_google
    assert !b3.exists_in_google
  end

  test 'bulk_upsert works' do
    Book.destroy_all
    books = [
      Book.new(
            author: 'Dr. Seuss',
            bib_id: 123,
            date: '1974',
            exists_in_hathitrust: false,
            exists_in_internet_archive: false,
            exists_in_google: false,
            hathitrust_access: nil,
            ia_identifier: nil,
            hathitrust_rights: nil,
            language: 'English',
            obj_id: 123,
            oclc_number: 123,
            raw_marcxml: nil,
            source_path: '/dev/null',
            subject: nil,
            title: 'Green Eggs and Ham',
            volume: nil),
      Book.new(
            author: 'Dr. Seuss',
            bib_id: 234,
            date: '1975',
            exists_in_hathitrust: false,
            exists_in_internet_archive: false,
            exists_in_google: false,
            hathitrust_access: nil,
            ia_identifier: nil,
            hathitrust_rights: nil,
            language: 'English',
            obj_id: 234,
            oclc_number: 234,
            raw_marcxml: nil,
            source_path: '/dev/null',
            subject: nil,
            title: 'The Lorax',
            volume: nil),
      Book.new( # same obj_id as the first one
            author: 'Dr. Seuss',
            bib_id: 123,
            date: '1975',
            exists_in_hathitrust: false,
            exists_in_internet_archive: false,
            exists_in_google: false,
            hathitrust_access: nil,
            ia_identifier: nil,
            hathitrust_rights: nil,
            language: 'English',
            obj_id: 123,
            oclc_number: 123,
            raw_marcxml: nil,
            source_path: '/dev/null',
            subject: nil,
            title: 'The Lorax',
            volume: nil)
    ]
    Book.bulk_upsert(books)
    assert_equal 2, Book.count
    assert_not_nil Book.find_by_obj_id(123)
    assert_not_nil Book.find_by_obj_id(234)
  end

  test 'internet_archive_url returns correct url based on IA identifier' do
    b1 = books(:one) #fixture data
    assert_equal "https://archive.org/details/#{b1.ia_identifier}", b1.internet_archive_url

  end

  test 'hathitrust_handle works only if book exists in hathitrust' do 
    b1 = books(:one)
    b4 = books(:four)

    assert !b1.exists_in_hathitrust
    assert_equal "", b1.hathitrust_handle

    assert b4.exists_in_hathitrust
    assert_equal "https://hdl.handle.net/2027/uiuc.#{b4.obj_id}", b4.hathitrust_handle
  end

  test 'from_marcxml_record returns a correct Book instance' do
    namespaces = { 'marc' => 'http://www.loc.gov/MARC21/slim' }
    key        = "/this/doesnt/matter"
    xml_file   = File.read('test/fixtures/files/sample.xml')
    record     = Nokogiri::XML(xml_file).xpath("//marc:record", namespaces)

    book = Book.from_marcxml_record(key: key, record: record)
    assert_equal key, book.source_path
    assert_equal 272087, book.bib_id
    assert_equal "03493895", book.oclc_number
    assert_equal "", book.author
    assert_equal "National Clearinghouse on Aging thesaurus", book.title
    assert_nil book.language
    assert_equal "Gerontology||Aging", book.subject
    assert_nil book.volume
    assert_equal "1977.", book.date
    assert_equal "30112048976390", book.obj_id
    assert_nil book.ia_identifier
  end

  test 'as_json returns book data as json data' do 
    b2 = books(:two)

    data = 
      
        {id: b2.id, bib_id: 2, oclc_number: "MyString", 
        obj_id: "2", title: "MyString", volume: "MyString", 
        author: "MyString", language: nil, subjects: nil, 
        date: "MyString", url: nil, catalog_url: b2.uiuc_catalog_url, hathitrust_url: nil, 
        hathitrust_rights: "MyString", hathitrust_access: nil, internet_archive_identifier: "MyString",
        internet_archive_url: nil, created_at: b2.created_at,
        updated_at: b2.updated_at}
      
    assert_equal data, b2.as_json
  end

  test 'as_message is wrapped as_json' do 
    b2 = books(:two)

    data = 
  
      {id: b2.id, bib_id: 2, oclc_number: "MyString", 
      obj_id: "2", title: "MyString", volume: "MyString", 
      author: "MyString", language: nil, subjects: nil, 
      date: "MyString", url: nil, catalog_url: b2.uiuc_catalog_url, hathitrust_url: nil, 
      hathitrust_rights: "MyString", hathitrust_access: nil, internet_archive_identifier: "MyString",
      internet_archive_url: nil, created_at: b2.created_at,
      updated_at: b2.updated_at}

    assert_equal data, b2.as_message 
    
  end

  test 'service returns which type of record the book is from' do 
    b5 = books(:five)
    b6 = books(:six)

    assert_equal Service::GOOGLE, b5.service
    assert_equal Service::INTERNET_ARCHIVE, b6.service
  end

  test 'to_csv returns correct csv format of book data' do 
    
    b2 = books(:two)
    # expected = "#{b2.bib_id},#{b2.id},#{b2.oclc_number},#{b2.obj_id},#{b2.title},#{b2.author},#{b2.volume},#{b2.date},#{b2.ia_identifier},#{b2.hathitrust_handle},#{b2.exists_in_hathitrust},#{b2.exists_in_internet_archive},#{b2.exists_in_google}"
    expected_csv = CSV.generate() do |csv|
      csv << ["#{b2.bib_id}", "#{b2.id}", "#{b2.oclc_number}", "#{b2.obj_id}", "#{b2.title}", "#{b2.author}", "#{b2.volume}", "#{b2.date}", "#{b2.ia_identifier}", "#{b2.hathitrust_handle}", "#{b2.exists_in_hathitrust}", "#{b2.exists_in_internet_archive}", "#{b2.exists_in_google}"]
    end
  
    assert_equal expected_csv, b2.to_csv({})
  end


  test 'uiuc_catalog_url returns the bib_id with prefix 99 and suffix 12205899' do 
    b1 = books(:one)
    bibid = b1.bib_id.to_s
    base_url = 'https://i-share-uiu.primo.exlibrisgroup.com/permalink/01CARLI_UIU/gpjosq/alma'
    prefix   = '99'
    suffix   = '12205899'

    assert bibid.present?
    assert_equal [base_url, prefix, bibid, suffix].join, b1.uiuc_catalog_url
  end

  test 'send_message(message) sends sqs message' do 
    message = { message: "This message" }
    book = Book.create(title: "Whatever")
    region = Configuration.instance.storage[:books][:region]
    
    sts_client_mock = Minitest::Mock.new 
    sts_client_mock.expect(:get_caller_identity, OpenStruct.new(account: '721945215539'))
    
    Aws::STS::Client.stub(:new, sts_client_mock) do 
      queue_url = "https://sqs.#{region}.amazonaws.com/721945215539/book-tracker-demo"

      sqs_client_mock = Minitest::Mock.new 
      sqs_client_mock.expect(:send_message, nil, [{ queue_url: queue_url, message_body: message.to_json, message_attributes: {} }])

      Aws::SQS::Client.stub(:new, sqs_client_mock) do 
        book.send_message(message)
      end

      assert_mock sqs_client_mock
      assert_mock sts_client_mock 
    end
  end
end
